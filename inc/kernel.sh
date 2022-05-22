#!/bin/bash

build_kernel()
{
    # do preparation steps
    echo "### Cloning linux kernel $kernel_branch"

    if [[ $kernel_branch == *linux* ]]; then
        kernel_dir="${cache_dir}/$kernel_branch";
        kernel_config="config/$kernel_branch.config";
    else
        kernel_dir="${cache_dir}/linux-$kernel_branch";
        kernel_config="config/linux-$kernel_branch.config";
    fi
    
    if [[ $GHRUNNER == 'on' ]]; then
        rm -rf "${output_dir}"
    fi

    # generate output directory
    mkdir -p "${output_dir}"
#    mkdir -p "${boot_dir}"

    cleaned_or_new=0

    if [ ! -d ${kernel_dir} ]; then
        echo "### Kernel dir does not exist, cloning kernel"

        mkdir -p "${kernel_dir}"

        # git clone linux tree
        git clone --branch "$kernel_branch" --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git "${kernel_dir}"

        cleaned_or_new=1

    else
        if [ ${CLEAN_KERNEL_SRC} = 'on' ]; then
            echo "### Kernel dir does exist. Fetching and cleaning"

            cd ${kernel_dir}

            git fetch --depth 1 origin "$kernel_branch"

            git checkout -f -q FETCH_HEAD
            git clean -qdf

            cd ${current_dir}
            
            cleaned_or_new=1
           
        else
            echo "### Kernel dir does exist. --clean not provided"
            echo "### Continuing with dirty kernel src"

        fi

    fi

    kernel_version=$(grab_version "${kernel_dir}");

    if [[ $kernel_version == 0 ]]; then
        rm -rf "${kernel_dir}"
        exit_with_error "### Error cloning kernel"
    fi
   
    if [[ $cleaned_or_new == 1 ]]; then
    
        if [[ $kernel_version == 3.* ]]; then
            # fix lk3.16.36 yylloc bug
            sed -i 's/YYLTYPE yylloc;/extern YYLTYPE yylloc;/' "${kernel_dir}"/scripts/dtc/dtc-lexer.lex.c_shipped
        fi
        
        # copy config and dts
        echo "### Moving kernel config in place"

        if [ ! -f ${kernel_config} ]; then
            cp config/vendor-3.16.36.config ${kernel_config}
        fi

        cp "${kernel_config}" "${kernel_dir}"/.config
        cp dts/*.dts "${kernel_dir}"/arch/arm/boot/dts/

    fi    
   

    # cleanup old modules for this kernel, this helps when rebuilding kernel with less modules
    if [ -d "${output_dir}"/lib/modules/"${kernel_version}" ]; then
    	rm -r "${output_dir}"/lib/modules/"$kernel_version"
    elif [ -d "${output_dir}"/lib/modules/"${kernel_version}"+ ]; then
    	rm -r "${output_dir}"/lib/modules/"$kernel_version"+
    fi


    # cd into linux source
    cd "${kernel_dir}"

    echo "### Starting make"

    if [ ${ALLOW_KERNEL_CONFIG_CHANGES} = 'on' ]; then
        $makehelp menuconfig
    fi
    $makehelp -j${THREADS} zImage 2>&1 | tee ${current_dir}/zImage.log
    $makehelp -j${THREADS} hap230.dtb 2>&1 | tee ${current_dir}/dtb.log
    cat arch/arm/boot/zImage arch/arm/boot/dts/hap230.dtb > zImage_and_dtb
    mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "${kernel_branch}" -d zImage_and_dtb "${output_dir}"/uImage-${kernel_version}
    rm zImage_and_dtb

    $makehelp -j${THREADS} modules 2>&1 | tee ${current_dir}/modules.log
    $makehelp -j${THREADS} INSTALL_MOD_PATH="${output_dir}" modules_install 2>&1 | tee -a ${current_dir}/modules.log

    cd "${current_dir}"

    echo "### Copying new kernel config to output"
    cp "${kernel_dir}"/.config "${output_dir}"/linux-${kernel_version}.config

#    echo "### Adding default ramdisk to output"
#    cp prebuilt/uRamdisk "${boot_dir}"

    # set permissions for later runnable files
#    chmod =rwxrxrx "${boot_dir}"/uRamdisk
    chmod =rwxrxrx "${output_dir}"/uImage-${kernel_version}

#    cp "${boot_dir}"/uImage-${kernel_version} "${boot_dir}"/uImage

#    echo "### Cleanup and tar results"
#    rm "${output_dir}"/lib/modules/*/source
#    rm "${output_dir}"/lib/modules/*/build

    # tar and compress modules for easier transport
#    cd "${output_dir}"/lib/modules/
#    if [ -d "${kernel_version}" ]; then
#    	tar -czf "${output_dir}"/modules-${kernel_version}.tar.gz "${kernel_version}"
#    elif [ -d "${kernel_version}"+ ]; then
#    	tar -czf "${output_dir}"/modules-${kernel_version}+.tar.gz "${kernel_version}"+
#    else
#    	echo "### Failed to tar up modules folder! It might be missing from the output."
#    fi

    cd "${output_dir}"
#    tar -czf "${output_dir}"/boot-${kernel_version}.tar.gz boot/uRamdisk boot/uImage-${kernel_version} boot/uImage boot/linux-${kernel_version}.config

#    rm "${boot_dir}"/uImage

    cd "${current_dir}"

    return

    # abort point for github runner to keep it from messing with permissions
    if [[ $GHRUNNER == 'on' ]]; then
        exit 0
    fi

    # fix permissions on folders for usability
    chown "root:sudo" "${cache_dir}"
    chown "root:sudo" "${cache_dir}"/*

    chown "root:sudo" "${output_dir}"
    chown "root:sudo" "${output_dir}"/*
#    chown "root:sudo" "${output_dir}"/lib

#    if [ -f "${output_dir}"/modules-${kernel_version}.tar.gz ]; then
#    	chown "${current_user}:sudo" "${output_dir}"/modules-${kernel_version}.tar.gz
#	fi
#    if [ -f "${output_dir}"/modules-${kernel_version}+.tar.gz ]; then
#   	    chown "${current_user}:sudo" "${output_dir}"/modules-${kernel_version}+.tar.gz
#    fi

#    chown "${current_user}:sudo" "${output_dir}"/boot-${kernel_version}.tar.gz

    chmod "g+rw" "${cache_dir}"
    chmod "g+rw" "${cache_dir}"/*
    chmod "g+rw" "${output_dir}"
    chmod "g+rw" "${output_dir}"/*
#    chmod -R "g+rw" "${boot_dir}"
#    chmod "g+rw" "${output_dir}"/lib

}
