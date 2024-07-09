#!/bin/bash

if [ ! -d ${DIRECTORY} ]; then
        sudo mkdir -p ${DIRECTORY}
fi

########################################################################
# Etech-System RHOSP13-test DCN Add Template Make Script 
# Ver 20230324 by hkjeon@etechsystem.co.kr
#   - First Release
########################################################################
SCRIPT_VERSION="20230324"
DIRECTORY="/root/hk-scripts/openstack-script"
DATE=$(date +%Y%m%d%H)
compute_path="/home/stack/templates/leaf-spine-region"

########################################################################
### Undercloud (Director) Variables
########################################################################
compute_name="#test-vvnf73"
az_subnet="AZ-19-COMP-LTE-test" 
pxe_cidr="192.13.102.64/27"
dhcp_start=192.13.102.71
dhcp_end=192.13.102.78
inspection_iprange_start=192.13.102.85
inspection_iprange_end=192.13.102.94
az_gateway=192.13.102.65
node_role_name="compute-test-vvnf73"
node_count=8


########################################################################
### Overcloud Variables
########################################################################
compute_hostname="rhosp-az0-comp-vvnf73"
pxe_nic="eno1"
bond_mem_1="eno3"
bond_mem_2="eno4"
dpdk_nic_1="ens1f0"
dpdk_nic_2="ens1f1"
physnet_name="physnet-az19-testvvnf-dpdk"
compute_yaml_path="${compute_path}/leaf19-testvvnf73"
Role_name="Computetestvvnf73"
Leaf_name="Leaf19"
mtu="1500"
ovs_type="dpdk"              # ovs or dpdk
cluster="az0"

pxe_ip_list="192.13.102.71 192.13.102.72 192.13.102.73 192.13.102.74 192.13.102.75 192.13.102.76 192.13.102.77 192.13.102.78"

InternalApi_network="InternalApitestvvnf73"
InternalApi_lower_network="internal_api_testvvnf73"
InternalApi_subnet="192.13.103.64/27"
InternalApi_gateway="192.13.103.65"
InternalApi_ip_pool_start="192.13.103.71"
InternalApi_ip_pool_end="192.13.103.78"
InternalApi_ip_vlan_id="1073"
inter_ip_list="192.13.103.71 192.13.103.72 192.13.103.73 192.13.103.74 192.13.103.75 192.13.103.76 192.13.103.77 192.13.103.78"

ExternalOam_network="ExternalOamtestvvnf73"
ExternalOam_lower_network="external_oam_testvvnf73"
ExternalOam_subnet="192.13.121.128/27"
ExternalOam_gateway="192.13.121.129"
ExternalOam_ip_pool_start="192.13.121.141"
ExternalOam_ip_pool_end="192.13.121.148"
ExternalOam_ip_vlan_id="2073"
exter_ip_list="192.13.121.141 192.13.121.142 192.13.121.143 192.13.121.144 192.13.121.145 192.13.121.146 192.13.121.147 192.13.121.148"



########################################################################
# This Variable is default for OpenStack Environment. Do Not Edit.
########################################################################
under_file="${DIRECTORY}/under-template.txt-$DATE"
over_file="${DIRECTORY}/over-template.txt-$DATE"
pxe_ip_count=`echo ${pxe_ip_list} | awk -F ' ' '{ print NF }'`
#inter_ip_count=`echo ${inter_ip_list} | awk -F ' ' '{ print NF }'`
#exter_ip_count=`echo ${exter_ip_list} | awk -F ' ' '{ print NF }'`
pxe_subnet=`echo ${pxe_cidr} | awk -F '/' '{ print $2}'`
Control_plane_num=`echo ${az_subnet} | awk -F '-' '{ print $2}'`



########################################################################
# Undercloud template 
########################################################################
function undercloud_conf 
{
echo "============ undercloud.conf"
echo "[DEFAULT]"
echo "subnets = $az_subnet"
echo
echo
echo "$compute_name"
echo "[$az_subnet]"
echo "cidr = $pxe_cidr"
echo "dhcp_start = $dhcp_start"
echo "dhcp_end = $dhcp_end"
echo "inspection_iprange = $inspection_iprange_start,$inspection_iprange_end"
echo "gateway = $az_gateway"
echo "masquerade = False"
}

########################################################################
function instack_file 
{
local node_num=0
local role_num=0
echo 
echo
echo "=========== instack_$node_role_name.yaml" 
echo "nodes:" 
while [ ${node_num} != ${node_count} ]; do
        node_num=`expr ${node_num} + 1`
        echo '  - "name": "'${compute_hostname}'-'${node_num}'"' 
        echo '    "pm_addr": "'${pa_addr}'"' 
        echo '    "mac": ""' 
        echo '    "pm_type": "ipmi"' 
        echo '    "pm_user": "admin"' 
        echo '    "pm_password": "hpinvent"' 
        echo '    "capabilities": "node:'${node_role_name}'-'${role_num}',boot_option:local,boot_mode:uefi"' 
        echo '    "deploy_interface": "direct"' 
        local role_num=`expr ${role_num} + 1`
        if [ ${node_num} -ne ${node_count} ]; then
                echo
        fi
done
}

########################################################################


########################################################################
# OverCloud template 
########################################################################
function composable_network 
{
echo
echo "============ composable-network.yaml"
echo "# --------------------------------------------------------------- #"
echo "- name: $InternalApi_network"
echo "  name_lower: $InternalApi_lower_network"
echo "  vip: false"
echo "  ip_subnet: '$InternalApi_subnet'"
echo "  allocation_pools: [{'start': '$InternalApi_ip_pool_start', 'end': '$InternalApi_ip_pool_end'}]"
echo "# --------------------------------------------------------------- #"
echo "- name: $ExternalOam_network"
echo "  name_lower: $ExternalOam_lower_network"
echo "  vip: false"
echo "  ip_subnet: '$ExternalOam_subnet'"
echo "  allocation_pools: [{'start': '$ExternalOam_ip_pool_start', 'end': '$ExternalOam_ip_pool_end'}]"
echo "# --------------------------------------------------------------- #"
}


########################################################################
function input_service
{
if [ ${ovs_type} == "ovs" ]; then
	rpm_list="Aide AuditD CACerts CertmongerUser ComputeNeutronCorePlugin ComputeNeutronL3Agent ComputeNeutronMetadataAgent ComputeNeutronOvsAgent Docker Iscsid Kernel LoginDefs MySQLClient NeutronSriovAgent NeutronSriovHostConfig NeutronDhaz0gent NeutronMetadataAgent NovaCompute NovaLibvirt NovaMigrationTarget Ntp ContainersLogrotateCrond RsyslogSidecar Securetty Sshd Timezone TripleoFirewall TripleoPackages Tuned"
elif [ ${ovs_type} == "dpdk" ]; then
	rpm_list="Aide AuditD CACerts CertmongerUser ComputeNeutronCorePlugin ComputeNeutronL3Agent ComputeNeutronMetadataAgent ComputeNeutronOvsDpdk Docker Iscsid Kernel LoginDefs MySQLClient NeutronSriovAgent NeutronSriovHostConfig NeutronDhaz0gent NeutronMetadataAgent NovaCompute NovaLibvirt NovaMigrationTarget Ntp ContainersLogrotateCrond RsyslogSidecar Securetty Sshd Timezone TripleoFirewall TripleoPackages Tuned"
fi
}

function composable_roles
{
	input_service 
echo
echo
echo "============ composable-roles.yaml" 
echo "###############################################################################"
echo "# Role: $Role_name ($Leaf_name)                                            #"
echo "###############################################################################"
echo "- name: $Role_name"
echo "  description: |"
echo "    Basic $Leaf_name $Role_name Node role"
echo "  CountDefault: 0"
echo "  networks:"
echo "    - $InternalApi_network"
echo "    - $ExternalOam_network"
echo "  HostnameFormatDefault: '%stackname%-$node_role_name-%index%'"
echo "  RoleParametersDefault:"
echo "    VhostuserSocketGroup: \"hugetlbfs\""
echo "    TunedProfileName: \"cpu-partitioning\""
echo "  disable_upgrade_deployment: True"
echo "  ServicesDefault:"
for rpm in ${rpm_list};do
        echo "    - OS::TripleO::Services::${rpm}"
done
}


########################################################################
function region_envir
{
echo
echo
echo "============ region-environment.yaml" 
echo "resource_registry:"
echo "  OS::TripleO::$Role_name::Net::SoftwareConfig: $compute_yaml_path/compute.yaml"
echo 
echo "parameter_defaults:"
echo "  # ------------------------------------------------------- #"
echo "  ServiceNetMap:"
echo "    ${Role_name}HostnameResolveNetwork: $InternalApi_lower_network"
echo 
echo "    ${Role_name}ControlPlaneSubnet: $az_subnet"
echo 
echo "# ------------------------------------------------------- #"
echo "  ControlPlane${Control_plane_num}DefaultRoute: $az_gateway"
echo "  ControlPlane${Control_plane_num}SubnetCidr: '$pxe_subnet'"
echo "# ------------------------------------------------------- #"
echo "  ${az_subnet}EC2MetadataIp: $az_gateway"
echo "# ------------------------------------------------------- #"
echo "  ${InternalApi_network}NetCidr: $InternalApi_subnet"
echo "  ${InternalApi_network}AllocationPools: [{'start': '$InternalApi_ip_pool_start', 'end': '$InternalApi_ip_pool_end'}]"
echo "  ${InternalApi_network}NetworkVlanID: $InternalApi_ip_vlan_id"
echo "# ------------------------------------------------------- #"
echo "# ------------------------------------------------------- #"
echo "  ${ExternalOam_network}NetCidr: $ExternalOam_subnet"
echo "  ${ExternalOam_network}AllocationPools: [{'start': '$ExternalOam_ip_pool_start', 'end': '$ExternalOam_ip_pool_end'}]"
echo "  ${ExternalOam_network}NetworkVlanID: $ExternalOam_ip_vlan_id"
echo "# ------------------------------------------------------- #"
}


########################################################################
function region_extra
{
echo
echo
echo "============ region-extraconfig.yaml"
echo "parameter_defaults:"
echo "  # ${Role_name}NetworkDeploymentActions: ['CREATE','UPDATE']" 
echo "  # ${Role_name}RemovalPolicies: []"
echo "  # ${Role_name}RemovalPoliciesMode: update"
echo
echo "  NeutronNetworkVLANRanges: ",$physnet_name"" 
echo "  NeutronML2PhysicalNetworkMtus: ",$physnet_name:$mtu""
echo
echo "# ------------------------------------------------------- #"
echo "    neutron::server::default_availability_zones:"
echo "      - '${az_subnet}'"
echo
echo "  # ------------------------------------------------------- #"
echo "  # **** ${Role_name} Parameters ****"
echo "  # ------------------------------------------------------- #"
echo "  # Configuration ${Role_name} ${Leaf_name} DPDK/PCIPT"
echo "  # ------------------------------------------------------- #"
echo "  ${Role_name}Parameters:"
echo "    KernelArgs: \"default_hugepagesz=1GB hugepagesz=1G hugepages=110 intel_iommu=on intel_iommu=pt vfio_iommu_type1.allow_unsafe_interrupts=1 nmi_watchdog=0 transparent_hugepage=never intel_idle.max_cstate=0 processor.max_cstate=1 idle=mwait nohpet nosoftlockup isolcpus=1-13,15-27,29-41,43-55\""
echo "    TunedProfileName: \"cpu-partitioning\""
echo "    IsolCpusList: \"1-13,15-27,29-41,43-55\""
echo "    NovaVcpuPinSet: ['2-13','16-27','30-41','44-55']"
echo "    OvsDpdkCoreList: \"0,14,28,42\""
echo "    NovaComputeCpuSharedSet: \"0,14,28,42\""
echo "    OvsPmdCoreList: \"1,15,29,43\""
echo "    NovaReservedHostMemory: 16384"
echo "    OvsDpdkMemoryChannels: \"4\""
if [ ${mtu} -eq 1500 ]; then

        echo "    OvsDpdkSocketMemory: \"1024,1024\""

elif [ ${mtu} -eq 2000 ]; then
        echo "    OvsDpdkSocketMemory: \"2048,2048\""

elif [ ${mtu} -eq 9000 ]; then
        echo "    OvsDpdkSocketMemory: \"4096,4096\""

fi
echo "    NovaLibvirtRxQueueSize: 1024"
echo "    NovaLibvirtTxQueueSize: 1024"
echo "    VhostuserSocketGroup: \"hugetlbfs\""
echo "    NeutronBridgeMappings:"
echo "      - $physnet_name:br-dpdkbond0"
echo "    ExtraSysctlSettings:"
echo "      net.netfilter.nf_conntrack_max:"
echo "        value: 1000000"
echo "      net.nf_conntrack_max:"
echo "        value: 1000000"
echo "      net.ipv6.conf.all.disable_ipv6:"
echo "        value: 1"
echo "      kernel.sysrq:"
echo "        value: 1"
echo "  # ------------------------------------------------------- #"
echo "    NovaPCIPassthrough:"
echo "      - vendor_id: \"8086\""
echo "        product_id: \"1583\""
echo "        address: \"0000:82:00.0\""
echo "      - vendor_id: \"8086\""
echo "        product_id: \"1583\""
echo "        address: \"0000:82:00.1\""
echo "  # ------------------------------------------------------- #"
echo
echo "  # ------------------------------------------------------- #"
echo "  # **** ${Role_name} Extraconfig ****"
echo "  # ------------------------------------------------------- #"
echo "  # ${Role_name} ${Leaf_name} ExtraConfig"
echo "  # ------------------------------------------------------- #"
echo "  ${Role_name}ExtraConfig:"
echo "    neutron::agents::ml2::ovs::enable_security_group: true"
echo "    neutron::plugins::ml2::enable_security_group: true"
echo "    nova::compute::allow_resize_to_same_host: true"
echo "    nova::compute::force_config_drive: true"
echo "    nova::compute::resume_guests_state_on_host_boot: true"
echo "    nova::compute::libvirt::libvirt_inject_password: true"
echo "    nova::compute::libvirt::libvirt_inject_key: true"
echo "    nova::compute::libvirt::libvirt_inject_partition: -1"
echo "    nova::compute::libvirt::vncserver_listen: \"%{hiera('${InternalApi_lower_network}')}\""
echo "    nova::compute::vncserver_proxyclient_address: \"%{hiera('$InternalApi_lower_network')}\""
echo "    cold_migration_ssh_inbound_addr: \"%{hiera('$InternalApi_lower_network')}\""
echo "    live_migration_ssh_inbound_addr: \"%{hiera('$InternalApi_lower_network')}\""
echo "    nova::migration::libvirt::live_migration_inbound_addr: \"%{hiera('$InternalApi_lower_network')}\""
echo "    nova::my_ip: \"%{hiera('$InternalApi_lower_network')}\""
echo "    tripleo::profile::base::database::mysql::client::mysql_client_bind_address: \"%{hiera('$InternalApi_lower_network')}\""
echo "    nova::pci::aliases:"
echo "      - name: \"pcipt40g01\""
echo "        device_type: \"type-PF\""
echo "        vendor_id: \"8086\""
echo "        product_id: \"1583\""
echo "    # ---- Add availability zone Neutron ---- #"
echo "    neutron::agents::dhcp::availability_zone: ${az_subnet}"
echo "    # ---- Add availability zone Neutron ---- #"
echo "  # ------------------------------------------------------- #"
}

########################################################################
function host_name
{
local node_num=0
echo
echo
echo "============ region-hostnamemap.yaml"
echo "parameter_defaults:"
echo "  ${Role_name}SchedulerHints:"
echo "    'capabilities:node': '${node_role_name}-%index%'"
echo
echo "HostnameMap:"
echo "    #-----------------------------------------------------------#"
echo "    # Leaf${Control_plane_num}                                                   #"
echo "    #-----------------------------------------------------------#"
while [ ${node_num} != ${node_count} ]; do
        echo "  overcloud-$node_role_name-${node_num}: $compute_hostname-`expr ${node_num} + 1`"
        node_num=`expr ${node_num} + 1`
done
}



########################################################################
function region_node
{
echo
echo
echo "============ region-nodecount.yaml"
echo "parameter_defaults:"
echo "  Overcloud${Role_name}Flavor: baremetal"
echo "  ${Role_name}Count: $node_count"
}


########################################################################
function insert_ip_with_for
{
ip_list=${*}
for ip in ${ip_list}
do
echo "    - ${ip}"
done
}


########################################################################
function ip_addr
{
echo
echo
echo "============ region-ip-address.yaml"
echo "resource_registry:"
echo "  OS::TripleO::Network::$InternalApi_network: /usr/share/openstack-tripleo-heat-templates/network/$InternalApi_lower_network.yaml"
echo "  OS::TripleO::Network::$ExternalOam_network: /usr/share/openstack-tripleo-heat-templates/network/$ExternalOam_lower_network.yaml"
echo
echo "  OS::TripleO::$Role_name::Ports::${InternalApi_network}Port: /usr/share/openstack-tripleo-heat-templates/network/ports/${InternalApi_lower_network}_from_pool.yaml"
echo "  OS::TripleO::$Role_name::Ports::${ExternalOam_network}Port: /usr/share/openstack-tripleo-heat-templates/network/ports/${ExternalOam_lower_network}_from_pool.yaml"
echo
echo
echo "  # ------------------------------------------------------------- #"
echo "  # Leaf$Control_plane_num $Role_name IPs Pool"
echo "  # ------------------------------------------------------------- #"
echo "  ${Role_name}IPs:"
echo "    ctlplane:"
insert_ip_with_for ${pxe_ip_list}
echo
echo "    $InternalApi_lower_network:"
insert_ip_with_for ${inter_ip_list}
echo
echo "    $ExternalOam_lower_network:"
insert_ip_with_for ${exter_ip_list}
echo
}


########################################################################
function compute_info
{
echo
echo
echo "============ compute.yaml "
echo "heat_template_version: queens"
echo "description: >"
echo "  Software Config to drive os-net-config to configure VLANs for the Compute role."
echo "# ---------------------------------------------------- #"
echo "parameters:"
echo "  ControlPlaneIp:"
echo "    type: string"
echo "# --------------------------- #"
echo "  ${InternalApi_network}IpSubnet:"
echo "    type: string"
echo "  ${InternalApi_network}NetworkVlanID:"
echo "    type: number"
echo "# --------------------------- #"
echo "  ${ExternalOam_network}IpSubnet:"
echo "    type: string"
echo "  ${ExternalOam_network}NetworkVlanID:"
echo "    type: number"
echo "# --------------------------- #"
echo
echo "# --------------------------- #"
echo "  ControlPlane${Control_plane_num}SubnetCidr:"
echo "    type: string"
echo "  ControlPlane${Control_plane_num}DefaultRoute:"
echo "    type: string"
echo "  ${az_subnet}EC2MetadataIp:"
echo "    type: string"
echo "# ---------------------------------------------------- #"
echo "resources:"
echo "  OsNetConfigImpl:"
echo "    type: OS::Heat::SoftwareConfig"
echo "    properties:"
echo "      group: script"
echo "      config:"
echo "        str_replace:"
echo "          template:"
echo "            get_file: /usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh"
echo "          params:"
echo "	    \$network_config:"
echo "              network_config:"
echo "# ---------------------------------------------------- #"
echo "              - type: interface"
echo "                name: $pxe_nic"
echo "                use_dhcp: false"
echo "                addresses:"
echo "                - ip_netmask:"
echo "                    list_join:"
echo "                    - /"
echo "                    - - get_param: ControlPlaneIp"
echo "                      - get_param: ControlPlane${Control_plane_num}SubnetCidr"
echo "                routes:"
echo "                - ip_netmask: 169.254.169.254/32"
echo "                  next_hop:"
echo "                    get_param: ${az_subnet}EC2MetadataIp"
if [ ${cluster} == "az0" ]; then
echo "                - ip_netmask: 192.14.233.0/27"
echo "                  next_hop: $az_gateway"
elif [ ${cluster} == "cpb" ]; then
echo "                - ip_netmask: 192.14.233.32/27"
echo "                  next_hop: $az_gateway"
fi
echo "# ---------------------------------------------------- #"
echo "              - type: linux_bond"
echo "                name: bond0"
echo "                use_dhcp: false"
echo "                bonding_options: \"mode=active-backup miimon=100\""
echo "                members:"
echo "                  - type: interface"
echo "                    name: $bond_mem_1"
echo "                    use_dhcp: false"
echo "                  - type: interface"
echo "                    name: $bond_mem_2"
echo "                    use_dhcp: false"
echo "# ---------------------------------------------------- #"
echo "              - type: vlan"
echo "                device: bond0"
echo "                use_dhcp: false"
echo "                vlan_id:"
echo "                  get_param: ${InternalApi_network}NetworkVlanID"
echo "                addresses:"
echo "                - ip_netmask:"
echo "                    get_param: ${InternalApi_network}IpSubnet"
echo "                routes:"
if [ ${cluster} == "az0" ]; then
echo "                - ip_netmask: 192.14.234.0/27"
echo "                  next_hop: $InternalApi_gateway"
echo "                - ip_netmask: 192.14.236.0/27"
echo "                  next_hop: $InternalApi_gateway"
elif [ ${cluster} == "cpb" ]; then
echo "                - ip_netmask: 192.14.234.32/27"
echo "                  next_hop: $InternalApi_gateway"
echo "                - ip_netmask: 192.14.236.32/27"
echo "                  next_hop: $InternalApi_gateway"
fi
echo "# ---------------------------------------------------- #"
echo "              - type: vlan"
echo "                device: bond0"
echo "                use_dhcp: false"
echo "                vlan_id:"
echo "                  get_param: ${ExternalOam_network}NetworkVlanID"
echo "                addresses:"
echo "                - ip_netmask:"
echo "                    get_param: ${ExternalOam_network}IpSubnet"
echo "                routes:"
echo "                - default: true"
echo "                  next_hop: $ExternalOam_gateway"
echo "# ---------------------------------------------------- #"
echo "              - type: ovs_user_bridge"
echo "                name: br-dpdkbond0"
echo "                use_dhcp: false"
echo "                mtu: $mtu"
echo "                members:"
echo "                  - type: ovs_dpdk_bond"
echo "                    name: dpdkbond0"
echo "                    rx_queue: 2"
echo "                    use_dhcp: false"
echo "                    mtu: $mtu"
echo "                    ovs_options: \"bond_mode=balance-slb lacp=active other_config:lacp-time=fast other_config:bond-detect-mode=miimon other_config:bond-miimon-interval=100\""
echo "                    members:"
echo "                      - type: ovs_dpdk_port"
echo "                        name: dpdk0"
echo "                        members:"
echo "                          - type: interface"
echo "                            name: $dpdk_nic_1"
echo "                            mtu: $mtu"
echo "                      - type: ovs_dpdk_port"
echo "                        name: dpdk1"
echo "                        members:"
echo "                          - type: interface"
echo "                            name: $dpdk_nic_2"
echo "                            mtu: $mtu"
echo "# ---------------------------------------------------- #"
echo "outputs:"
echo "  OS::stack_id:"
echo "    description: The OsNetConfigImpl resource."
echo "    value:"
echo "      get_resource: OsNetConfigImpl"
echo
}


########################################################################
if [[ ${#} -ne 0 ]] && [[ ${1} == "-a" ]];then
	undercloud_conf >> $under_file
	instack_file >> $under_file
	composable_network >> $over_file
	composable_roles >> $over_file
	region_envir >> $over_file
	region_extra >> $over_file
	region_node >> $over_file
	compute_info >> $over_file
	host_name >> $over_file
	ip_addr >> $over_file

elif [[ ${#} -ne 0 ]] && [[ ${1} == "-u" ]]; then
	undercloud_conf >> $under_file
	instack_file >> $under_file
	
elif [[ ${#} -ne 0 ]] && [[ ${1} == "-o" ]]; then
        composable_network >> $over_file
	composable_roles >> $over_file
	region_envir >> $over_file
	region_extra >> $over_file
	region_node >> $over_file
	compute_info >> $over_file
	host_name >> $over_file
	ip_addr >> $over_file

elif [[ ${#} -ne 0 ]] && [[ ${1} == "-v" ]]; then
	echo "This Script Version: $SCRIPT_VERSION"

elif [ ${#} -eq 0 ]; then
        echo "Usage: "
        echo "	Execute Example: ./template-create.sh -a or -u or -o or -v"
        echo "	'-a' : make template for undercloud and overcloud"
        echo "	'-u' : make template for undercloud"
        echo "	'-o' : make template for overcloud"
	echo "	'-v' : print this script version" 
        exit
fi

