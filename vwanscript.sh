rg=VWAN_HUB_DEMO
region=WestEurope

az extension add --name virtual-wan

az group create -n $rg -l $region

# create vnets and subnets
## SPOKES
az network vnet create -n VNET_SPOKE1 -g $rg --address-prefixes 10.100.3.0/24
az network vnet subnet create -n WEB -g $rg --vnet-name VNET_SPOKE1 --address-prefixes 10.100.3.0/26
az network vnet subnet create -n WORKER -g $rg --vnet-name VNET_SPOKE1 --address-prefixes 10.100.3.64/26
az network vnet subnet create -n DB -g $rg --vnet-name VNET_SPOKE1 --address-prefixes 10.100.3.128/26

az network vnet create -n VNET_SPOKE2 -g $rg --address-prefixes 10.100.4.0/24
az network vnet subnet create -n WEB -g $rg --vnet-name VNET_SPOKE2 --address-prefixes 10.100.4.0/26
az network vnet subnet create -n WORKER -g $rg --vnet-name VNET_SPOKE2 --address-prefixes 10.100.4.64/26
az network vnet subnet create -n DB -g $rg --vnet-name VNET_SPOKE2 --address-prefixes 10.100.4.128/26

##DMZs
az network vnet create -n VNET_DMZ_IN -g $rg --address-prefixes 10.100.2.0/24
az network vnet subnet create -n UNTRUST -g $rg --vnet-name VNET_DMZ_IN --address-prefixes 10.100.2.0/26
az network vnet subnet create -n TRUST -g $rg --vnet-name VNET_DMZ_IN --address-prefixes 10.100.2.64/26
az network vnet subnet create -n MANAGEMENT -g $rg --vnet-name VNET_DMZ_IN --address-prefixes 10.100.2.128/26

az network vnet create -n VNET_DMZ_OUT -g $rg --address-prefixes 10.100.5.0/24
az network vnet subnet create -n UNTRUST -g $rg --vnet-name VNET_DMZ_OUT --address-prefixes 10.100.5.0/26
az network vnet subnet create -n TRUST -g $rg --vnet-name VNET_DMZ_OUT --address-prefixes 10.100.5.64/26
az network vnet subnet create -n MANAGEMENT -g $rg --vnet-name VNET_DMZ_OUT --address-prefixes 10.100.5.128/26

# create vwan and vhub
az network vwan create -g $rg -n VWAN --location $region --type Standard
az network vhub create -g $rg -n VWAN_HUB --address-prefix 10.100.1.0/24 --vwan VWAN

az extension add --name express-route

# create ER GW inside of vhub
az network express-route gateway create --name ER_GW --resource-group $rg --virtual-hub VWAN_HUB --location $region

# add circuit peer to ER GW inside of vhub
ER_CIRCUIT_RG=RG_US_W2_ER
CIRCUIT_NAME=ER_CIRCUIT
peeringID=`az network express-route peering show -g $ER_CIRCUIT_RG --circuit-name $CIRCUIT_NAME --name AzurePrivatePeering | jq -r .id`
az network express-route gateway connection create -g $rg -n ER_CONN --gateway-name ER_GW --peering $peeringID

# connect vnets to vhub
az network vhub connection create -g $rg --vhub-name VWAN_HUB --remote-vnet VNET_SPOKE1 --name CONN_SPOKE1
az network vhub connection create -g $rg --vhub-name VWAN_HUB --remote-vnet VNET_SPOKE2 --name CONN_SPOKE2
az network vhub connection create -g $rg --vhub-name VWAN_HUB --remote-vnet VNET_DMZ_IN --name CONN_DMZ_IN
az network vhub connection create -g $rg --vhub-name VWAN_HUB --remote-vnet VNET_DMZ_OUT --name CONN_DMZ_OUT

# cross peer spokes to dmz out
az network vnet peering create -g $rg -n PEER_SPOKE1_DMZ_OUT --remote-vnet VNET_DMZ_OUT --vnet-name VNET_SPOKE1 --allow-forwarded-traffic --allow-vnet-access
az network vnet peering create -g $rg -n PEER_DMZ_OUT_SPOKE1 --remote-vnet VNET_SPOKE1 --vnet-name VNET_DMZ_OUT --allow-forwarded-traffic --allow-vnet-access

az network vnet peering create -g $rg -n PEER_SPOKE2_DMZ_OUT --remote-vnet VNET_DMZ_OUT --vnet-name VNET_SPOKE2 --allow-forwarded-traffic --allow-vnet-access
az network vnet peering create -g $rg -n PEER_DMZ_OUT_SPOKE2 --remote-vnet VNET_SPOKE2 --vnet-name VNET_DMZ_OUT --allow-forwarded-traffic --allow-vnet-access

# using azure firewall for DMZs
az extension add --name azure-firewall

az network firewall create -g $rg -n FW_DMZ_IN --location $region
az network vnet subnet create -n AzureFirewallSubnet -g $rg --vnet-name VNET_DMZ_IN --address-prefixes 10.100.2.192/26
az network public-ip create -n PIP_FW_DMZ_IN -g $rg --sku Standard
az network firewall ip-config create -g $rg -f FW_DMZ_IN -n FW_IP_CONFIG_DMZ_IN --public-ip-address PIP_FW_DMZ_IN --vnet-name VNET_DMZ_IN
az network firewall update -g $rg -n FW_DMZ_IN --private-ranges 255.255.255.255/32

az network firewall create -g $rg -n FW_DMZ_OUT --location $region
az network vnet subnet create -n AzureFirewallSubnet -g $rg --vnet-name VNET_DMZ_OUT --address-prefixes 10.100.5.192/26
az network public-ip create -n PIP_FW_DMZ_OUT -g $rg --sku Standard
az network firewall ip-config create -g $rg -f FW_DMZ_OUT -n FW_IP_CONFIG_DMZ_OUT --public-ip-address PIP_FW_DMZ_OUT --vnet-name VNET_DMZ_OUT
az network firewall update -g $rg -n FW_DMZ_OUT --private-ranges 255.255.255.255/32

# add hub route for spoke vnets to next hop to dmz_in firewall
az network vhub route add -g $rg --vhub-name VWAN_HUB --address-prefixes 10.100.3.0/24 10.100.4.0/24 --next-hop 10.100.2.196

# create route table to send spoke to corp traffic thru the dmz_out firewall
az network route-table create -g $rg -n RT_SPOKE_TO_DMZ_OUT
az network route-table route create -g $rg --route-table-name RT_SPOKE_TO_DMZ_OUT \
  -n SPOKE-TO-CORP --address-prefix 10.1.0.0/20 --next-hop-type VirtualAppliance --next-hop-ip-address 10.100.5.196

# az network route-table route create -g $rg --route-table-name RT_SPOKE_TO_DMZ_OUT \
#   -n SPOKE-TO-INTERNET --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address 10.100.5.196

# apply route table to web subnets on the spoke vnets
az network vnet subnet update -g $rg --vnet-name VNET_SPOKE1 -n WEB --route-table RT_SPOKE_TO_DMZ_OUT
az network vnet subnet update -g $rg --vnet-name VNET_SPOKE2 -n WEB --route-table RT_SPOKE_TO_DMZ_OUT

# azure firewall rules to allow corp traffic to all dmz and spoke subnets
az network firewall network-rule create -g $rg -f FW_DMZ_OUT -c CORP \
  -n RULE_CORP_OUT --priority 100 --action Allow --source-addresses 10.100.0.0/16 --protocols Any \
  --destination-addresses 10.1.0.0/20 --destination-port "*"

az network firewall network-rule create -g $rg -f FW_DMZ_IN -c CORP \
  -n RULE_CORP_IN --priority 100 --action Allow --source-addresses 10.1.0.0/20 --protocols Any \
  --destination-addresses 10.100.0.0/16 --destination-port "*"

# application rule for fun
# az network firewall application-rule create -g $rg -f FW_DMZ_OUT -n TRUSTED_WEB -c CORP_WEB \
#   --protocols "HTTPS=443" --source-addresses 10.100.0.0/16 --target-fqdns "*.microsoft.com" "*.linkedin.com" "*.github.com" \
#   --action Allow --priority 100

# network security groups to allow spoke traffic
az network nsg create -g $rg -n NSG_SPOKE

az network nsg rule create -g $rg --nsg-name NSG_SPOKE -n RULE_ALLOW_CORP_OUT --priority 100 --direction Outbound \
  --source-address-prefixes VirtualNetwork --destination-address-prefixes 10.1.0.0/20 --destination-port-ranges "*"
az network nsg rule create -g $rg --nsg-name NSG_SPOKE -n RULE_ALLOW_SPOKE_TO_SPOKE_OUT --priority 200 --direction Outbound \
  --source-address-prefixes 10.100.0.0/16 --protocol "*" --destination-address-prefixes 10.100.0.0/16 --destination-port-ranges "*"

az network nsg rule create -g $rg --nsg-name NSG_SPOKE -n RULE_ALLOW_CORP_IN --priority 100 --direction Inbound \
  --source-address-prefixes 10.100.2.0/24 --destination-address-prefixes VirtualNetwork --destination-port-ranges "*"
az network nsg rule create -g $rg --nsg-name NSG_SPOKE -n RULE_ALLOW_SSH_IN --priority 200 --direction Inbound \
  --source-address-prefixes Internet --protocol Tcp --destination-address-prefixes VirtualNetwork --destination-port-ranges "22"
az network nsg rule create -g $rg --nsg-name NSG_SPOKE -n RULE_ALLOW_SPOKE_TO_SPOKE_IN --priority 110 --direction Inbound \
  --source-address-prefixes 10.100.0.0/16 --protocol "*" --destination-address-prefixes 10.100.0.0/16 --destination-port-ranges "*"

# apply NSGs to spoke vnets
az network vnet subnet update -g $rg --vnet-name VNET_SPOKE1 -n WEB --nsg NSG_SPOKE
az network vnet subnet update -g $rg --vnet-name VNET_SPOKE2 -n WEB --nsg NSG_SPOKE

# TODO: automate VM/VMSS into spoke vnets