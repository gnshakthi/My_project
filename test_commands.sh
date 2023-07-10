#!/bin/bash                                                                           
echo $0 

wireless_interface_mode_status() {                                                                
        interface_ap_count=0                                                          
        interface_non_ap_count=0                                                                  
        interface_non_ap_mode_name=""                                                 
        total_interfaces=$(iw dev | awk '$1=="Interface"{print $2}'|wc -l)  
        check_wireless_interface_mode() {                                                               
                                        interface=$1                                  
                                        mode=$(iw dev "$interface" info | awk '/type/ {print $2}')      
                                                                                      
                                        if [ "$mode" == "AP" ]; then        
                                                ((interface_ap_count++))                                
                                        else                                          
                                                ((interface_non_ap_count++))                            
                                                interface_non_ap_mode_name+=$interface
                                        fi                                  
        }                                                                                               
        interfaces=$(iw dev | awk '$1=="Interface"{print $2}')                        
        for interface in $interfaces; do                                                                
                check_wireless_interface_mode "$interface"                            
        done                                                                
        echo "Number of Wireless Interfaces : $total_interfaces"                                        
        if [[ $interface_non_ap_count -eq 0 ]];  then                                 
                echo "All The Intefaces Are Currently in AP Mode"                                       
        else                                                                          
                echo "Some Interface Are Currently in Non-AP Mode"        
                echo "Non-AP Interface List: "                                                          
                echo $interface_non_ap_mode_name                                      
        fi                                                                                              
}        

wireless_network_status() {                                                           
        interface_up_count=0                                                
        interface_down_count=0                                                                    
        down_interface_name=""                                                        
        total_interfaces=$(iw dev | awk '$1=="Interface"{print $2}'|wc -l)                        
        check_wireless_interface_status() {                                           
                        interface=$1                                        
                        status=$(ip link show "$interface" | grep -o "state [A-Z]\+" | awk '{print $2}')
                                                                                      
                         if [ "$status" == "UP" ]; then                                                 
                                ((interface_up_count++))                              
                        else                                                
                                ((interface_down_count++))                                              
                                down_interface_name+=$interface                       
                        fi                                                                              
        }                                                                             
        interfaces=$(iw dev | awk '$1=="Interface"{print $2}')              
        for interface in $interfaces; do                                                                
                check_wireless_interface_status "$interface"                          
        done                                                                                            
        echo "Number of Wireless Interfaces : $total_interfaces"                      
        if [[ $interface_down_count -eq 0 ]]; then                          
                echo "All The Intefaces Are Currently UP"                                               
        else                                                                          
                echo "$interface_down_count Interface Are Currently DOWN"                               
                echo "Down Interface List: "                                          
                echo $down_interface_name                                 
        fi                                                                                              
}      

network_interface() {                                                                 
        check_interface_status() {                                          
                interface=$1                                                                            
                status=$(ip link show "$interface" | grep -o "state [A-Z]\+" | awk '{print $2}')
                                                                                                        
                if [ "$status" == "UP" ]; then                                        
                        echo "interface $interface is UP"                   
                else                                                                                    
                        echo "interface $interface is DOWN"                                     
                fi                                                                                      
        }                                                                             
        interfaces=$(ip link show | awk -F ': ' '/^[0-9]+: .*: <BROADCAST,MULTICAST,UP,LOWER_UP/ {print $2}')
        for interface in $interfaces; do                                                                
                check_interface_status "$interface"                                             
        done                                                                                            
}   

route_status() {                                                                                        
                                                                                                
        check_erouter_route() {                                                                         
        local gw=$(ip route show default | awk '/default/ {print $3}')                
        if [ -z "$gw" ]; then                                                                                
                echo "Route for erouter is not set."                                                    
        else                                                                                    
                echo "Route for erouter is set. Gateway: $gw"                                           
        fi                                                                            
        }                                                                                                    
                                                                                                        
        check_ip_match() {                                                                      
        local interfaces=("brebhaul" "br0" "br106" "br403")                                             
        for interface in "${interfaces[@]}"; do                                       
                ip=$(ifconfig "$interface" | awk '/inet / {print substr($2, 6)}')                            
                if [ "$ip" = "$EXPECTED_IP" ]; then                                                     
                        echo "IP address matches with $interface: $ip"                          
                        return 0                                 
                fi                                                                    
        done                                                                                                 
        echo "IP address does not match with any specified interface."                                  
        return 1                                         
        }                                                                                               
                                                                                      
                                                                                                             
        check_erouter_route                                                                             
        echo "Enter The Expected IP :"                                                          
        read expectedip                                                                                 
        EXPECTED_IP="$expectedip"                                                               
        check_ip_match                                                                                       
}                 

service_status() {                                                                    
        check_service() {                                                                                    
                 service_status=$(systemctl is-active "$1" 2>&1)                                        
                 if [[ $service_status == "active" ]]; then                                     
                         return 0                                                                       
                 else                                                                 
                        return 1                                                                             
                 fi                                                                                     
        }                                                                                       
        all_services=$(systemctl list-units --type=service --all --no-pager --plain --no-legend | awk '{print $1}')
        running_count=0                                                               
        failed_count=0                                                                                       
        while IFS= read -r service; do                                                                  
        if check_service "$service"; then                                                       
                 ((running_count++))                                                                               
        else                                                                          
                ((failed_count++))                                                                           
        fi                                                                                              
        done <<< "$all_services"                                                                
        echo "Running services: $running_count"                                                                    
        echo "Failed services: $failed_count"                                         
        if [[ $failed_count -eq 0 ]]; then                                                                   
                echo "All The Services Are currently Running"                                           
        else                                                                                    
                echo "All The Services Are Not Running Now"                                                        
        fi                                                                            
}             

internet_status() {                                                                                                
        echo "Enter the Website"                                                                        
        read website                                                                            
        echo $(ping "$website")                                                                                    
}    

specific_service_status() {                                                                     
        echo "Enter the Service Name :"                                                                            
        read service                                                                  
        if systemctl is-active --quiet $service; then                                                        
                echo "$service service is active."                                                      
        else                                                                                    
                echo "$service service is not active."                                                             
        fi                                                                            
}       

mount_status() {                                                                                        
        expected_devices=(                                                                      
                "/dev/mmcblk0p2 /"                                                                                 
                "/dev/mmcblk0p1 /boot"                                                
        )                                                                                                    
                                                                                                        
        check_mount() {                                                                         
                device=$1                                                                                          
                mount_point=$2                                                        
                mount | grep -q "${device}"                                                                  
                if [ $? -eq 0 ]; then                                                                   
                        mount | grep -q "${device} on ${mount_point}"                           
                        if [ $? -eq 0 ]; then                                                                      
                                echo "Device ${device} is mounted at ${mount_point}"  
                        else                                                                                 
                                echo "Device ${device} is mounted at a different location:"             
                                echo "$(mount | grep ${device})"                                
                        fi                                                                                         
                else                                                                  
                        echo "Device ${device} is not mounted"                                               
                fi                                                                                      
        }                                                                                       
                                                                                                                   
        for entry in "${expected_devices[@]}"; do                                               
        device=$(echo ${entry} | awk '{print $1}')                                                           
        mount_point=$(echo ${entry} | awk '{print $2}')                                                 
        check_mount "${device}" "${mount_point}"                                                
        done                                                                                                       
}                     

usb_status() {                                                                        
        usb_count=$(lsusb | wc -l)                                                                           
        echo "Number of USB devices connected: $usb_count"                                              
        usb_info=$(lsusb)                                                                       
        echo "USB device information:"                                                                             
        echo "$usb_info"                                                              
}   

bridge_status() {                                                                               
        echo "$(brctl)"                                                                                            
        echo "Type what option you want"                                                        
        read command                                                                                         
        echo "$(brctl "$command")"                                                                      
}   

os_version() {                                                                        
        v1="Linux RaspberryPi-Gateway 5.10.52-v8 #1 SMP PREEMPT Thu Jun 8 11:42:06 UTC 2023 aarch64 GNU/Linux"     
        v2=$(uname -a)                                                                                  
        if [ "$v1" = "$v2" ]; then                                                              
                echo "OS Version"                                                                                  
                echo $v2                                                              
        else                                                                                                       
                echo "false"                                                                            
        fi                                                                                      
}                                                                                                                  
                                                                                      
board_id() {
        v1="1000000050b18808"
        v2=$(cat /proc/cpuinfo | grep -i serial|awk '{print$3}')
        v1=$(echo "$v1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        v2=$(echo "$v2" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        if [ "$v1" = "$v2" ]; then
                echo "Board Id"
                echo $v2
        else
                echo "false"
        fi
}
                                                                                                       
                                                                                                
board_model() {                                                                                                    
        v1="Raspberry Pi 4 Model B Rev 1.4"                                           
        v2=$(cat /proc/device-tree/model)                                                                    
        v1=$(echo "$v1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')                            
        v2=$(echo "$v2" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')                    
        if [ "$v1" = "$v2" ]; then                                                                                 
                echo "Board Model"                                                    
                echo $v2                                                                                     
        else                                                                                            
                echo "false"                                                                    
        fi                                                                                                         
}             

$1   
