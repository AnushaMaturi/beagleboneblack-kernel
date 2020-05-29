#!/bin/sh

##############################################
############     READ This  ##################
# Run the below command, output of this script file is copied in to "km-bbb-kernel-build.log" file it is useful for further analysis.
# $ ./km-bbb-kernel-build.sh | tee km-bbb-kernel-build.log
##############################################

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
NC='\033[0m'              # No Color
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

BRedU='\033[4;31m'         # Underline


make_pkg () {

	KERNEL_UTS="4.19.94-Kernel-Masters"
	#KERNEL_UTS=$(cat "include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g' )
        deployfile="-${pkg}.tar.gz"
        tar_options="--create --gzip --file"

        if [ -f "/home/$USER/out/${KERNEL_UTS}${deployfile}" ] ; then
                rm -rf "/home/$USER/out/${KERNEL_UTS}${deployfile}" || true
        fi

        if [ -d "$PWD/deploy/tmp" ] ; then
                rm -rf "$PWD/deploy/tmp" || true
        fi
        mkdir -p "$PWD/deploy/tmp"

        echo "${BGreen}-----------------------------"
        echo "${Red}Building ${pkg} archive...${NC}"

        case "${pkg}" in
        modules)
        	echo "${Red}make -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=\"$PWD/deploy/tmp${NC}"
                make -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH="$PWD/deploy/tmp"
                ;;
        dtbs)
        	echo "${Red}make -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs_install INSTALL_DTBS_PATH=\"$PWD/deploy/tmp${NC}"
                make -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs_install INSTALL_DTBS_PATH="$PWD/deploy/tmp"
                ;;
        esac

        echo "${Red}Compressing ${KERNEL_UTS}${deployfile}...${NC}"
        cd "$PWD/deploy/tmp" || true
        tar ${tar_options} "/home/$USER/out/${KERNEL_UTS}${deployfile}" ./*

        cd ../../
        rm -rf "deploy" || true

        if [ ! -f "/home/$USER/out/${KERNEL_UTS}${deployfile}" ] ; then
                export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}${deployfile}]"
                /bin/sh -e "$PWD/scripts/error.sh" && { exit 1 ; }
        else
                ls -lh "/home/$USER/out/${KERNEL_UTS}${deployfile}"
        fi
}

make_modules_pkg () {
        pkg="modules"
        make_pkg
}

make_dtbs_pkg () {
        pkg="dtbs"
        make_pkg
}


echo "${BRed}${BRedU}Step1: Setup kernel build Environment${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Check /home/$USER/out folder:"
echo "${Green}-----------------------------${NC}"

if [ -d /home/$USER/out ] ; then
	echo "${Red}/home/$USER/out folder is found${NC}"
	else
		echo "${Purple}/home/$USER/out folder is not found.${NC}"
		mkdir -p /home/$USER/out/
fi

echo "${Green}-----------------------------"
echo -n ${Red}"Check No. of CPUS:${NC}"
export cpus=`cat /proc/cpuinfo | grep processor | wc -l`
echo $cpus
echo "${Green}-----------------------------${NC}"
echo "";echo ""

echo "${BRed}${BRedU}Step2: kernel source code configuration${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Check .config file:"
echo "${Green}-----------------------------${NC}"
if [ -f .config ] ; then
        echo "${Red}~/.config file found.[Kernel Configuration has DONE]"
        echo "If you want to configure the kernel again type \"yes\" otherwise \"no\" to skip kernel configuration${NC}"
        read  temp
        if [ $temp = "yes" ];then
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
        fi
else
        echo "${Green}~/.config file not found [Kernel Configuration has not done]."
        echo "Please configure the kernel for further steps.${NC}"
        x=5
        while [ "$x" -ne 0 ]; do
                echo -n "$x "
                x=$(($x-1))
                sleep 1
        done
	echo "${Purple}make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- omap2plus_defconfig${NC}"
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- omap2plus_defconfig
        if [ -f .config ] ; then
                echo "${Green}Kernel Configuration has done successfully"
        else
                echo "${Red}Kernel Configuration is not done. exit here"
                exit 0
        fi
fi
echo "";echo ""

echo "${BRed}${BRedU}Step3: Build Kernel source code${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Build Kernel source code"
echo "${Green}-----------------------------${NC}"
echo "${Purple}make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j${cpus}${NC}"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j${cpus}

echo "${Green}-----------------------------"
echo "${Red}Build Device Tree Source."
echo "${Green}-----------------------------${NC}"
echo "${Purple}make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j${cpus}${NC}"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j${cpus}
echo "";echo ""

echo "${BRed}${BRedU}Step4: Build Kernel modules${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Build Kernel Modules."
echo "${Green}-----------------------------${NC}"
echo "${Purple}make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j${cpus}${NC}"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules -j${cpus}
echo "";echo ""

echo "${BRed}${BRedU}Step5: Install Kernel modules,dtb and zImage${NC}"
echo ""
echo "${Green}-----------------------------"
echo "${Red}Install Kernel Modules."
echo "${Green}-----------------------------${NC}"
make_modules_pkg


echo "${Green}-----------------------------"
echo "${Red}Install DTB."
echo "${Green}-----------------------------${NC}"
make_dtbs_pkg

echo "${Green}-----------------------------"
echo "${Red}Install zImage."
echo "${Green}-----------------------------${NC}"
echo "${Purple}make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- install -j${cpus}${NC}"
image="zImage"
KERNEL_UTS="4.19.94-Kernel-Masters"
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-  INSTALL_PATH=/home/$USER/out/ install 
        if [ -f "/home/$USER/out/${KERNEL_UTS}.${image}" ] ; then
                rm -rf "/home/$USER/out/${KERNEL_UTS}.${image}" || true
                rm -rf "/home/$USER/out/config-${KERNEL_UTS}" || true
        fi

        if [ -f ./arch/arm/boot/${image} ] ; then
                cp -v ./arch/arm/boot/${image} "/home/$USER/out/${KERNEL_UTS}.${image}"
                cp -v .config "/home/$USER/out/config-${KERNEL_UTS}"
        fi

        if [ ! -f "/home/$USER/out/${KERNEL_UTS}.${image}" ] ; then
                export ERROR_MSG="File Generation Failure: [${KERNEL_UTS}.${image}]"
                /bin/sh -e "$PWD/scripts/error.sh" && { exit 1 ; }
        else
                ls -lh "/home/$USER/out/${KERNEL_UTS}.${image}"
        fi

# parse commandline options
while [ ! -z "$1" ] ; do
        case $1 in
        -h|--help)
                echo "${Red}./km_build_uboot.sh [--board <value>]${NC}"
                ;;
        --board)
		echo "${Purple}cp /home/$USER/out/${KERNEL_UTS}-zImage /media/board$2/vmlinuz-${KERNEL_UTS}${NC}"
		cp /home/$USER/out/${KERNEL_UTS}-zImage /media/board$2/vmlinuz-${KERNEL_UTS}
		echo "${Purple}cp arch/arm/boot/dts/am335x-boneblack.dtb /meida/board$2/${NC}"
		cp arch/arm/boot/dts/am335x-boneblack.dtb /media/board$2/
		echo "${Purple} echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt ${NC}"
		echo uname_r=${KERNEL_UTS} > /media/board$2/uEnv.txt
		echo "${Purple} echo board_no=$2 >> /media/board$2/uEnv.txti${NC}"
		echo board_no=$2 >> /media/board$2/uEnv.txt
		#echo "${Purple}scp /home/$USER/out/vmlinuz-${KERNEL_UTS}  /home/$USER/out/${KERNEL_UTS}-modules.tar.gz /home/$USER/out/${KERNEL_UTS}-dtbs.tar.gz km@192.168.1.1$2:~/$NC"
                #scp /home/$USER/out/vmlinuz-${KERNEL_UTS}  /home/$USER/out/${KERNEL_UTS}-modules.tar.gz /home/$USER/out/${KERNEL_UTS}-dtbs.tar.gz km@192.168.1.1$2:~/
                ;;
        esac
        shift
done
