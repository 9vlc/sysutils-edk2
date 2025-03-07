#!/bin/sh
# shell include, do not run alone

# global deps
dependencies="python3 py311-pexpect gmake bash"

cat << EOL
src_dir            :: ${src_dir:-[none]}
src_use_git        :: ${src_use_git:-[none]}
src_reset_rebuild  :: ${src_reset_rebuild:-[none]}
src_branch         :: ${src_branch:-[none]}
gcc_native_version :: ${gcc_native_version:-[none]}
shim_dir           :: ${shim_dir:-[none]}

EOL

ovmf_target="$(uppercase $ovmf_target)"
if [ "$ovmf_target" != DEBUG ] && [ "$ovmf_target" != RELEASE ]; then
	err="resolve ovmf_target"
	return 1
fi

ovmf_plat="$(lowercase $ovmf_plat)"

# the great switch case
case "$ovmf_plat" in
	fvp)
		ovmf_arch="AARCH64"
		ovmf_cross_pkg="aarch64-none-elf-gcc"
		ovmf_args="$ovmf_args -D X64EMU_ENABLE=FALSE -D CAPSULE_ENABLE=FALSE"
		ovmf_platfile="Platform/ARM/VExpressPkg/ArmVExpress-FVP-AArch64.dsc"
		ovmf_result="ArmVExpress-FVP-AArch64/${ovmf_target}_GCC/FV/FVP_AARCH64_EFI.fd"
		ovmf_filename="FVP_AARCH64_EFI.fd"
	;;
	macchiatobin)
		ovmf_arch="AARCH64"
		ovmf_cross_pkg="aarch64-none-elf-gcc"
		ovmf_args="$ovmf_args -D X64EMU_ENABLE=TRUE -D CAPSULE_ENABLE=FALSE"
		ovmf_platfile="Platform/SolidRun/Armada80x0McBin/Armada80x0McBin.dsc"
		ovmf_result="Armada80x0McBin-AARCH64/${ovmf_target}_GCC/FV/ARMADA_EFI.fd"
		ovmf_filename="ARMADA_EFI.fd"
	;;
	rpi3)
		ovmf_arch="AARCH64"
		ovmf_cross_pkg="aarch64-none-elf-gcc"
		ovmf_args="$ovmf_args -D X64EMU_ENABLE=FALSE -D CAPSULE_ENABLE=FALSE"
		ovmf_platfile="Platform/RaspberryPi/RPi3/RPi3.dsc"
		ovmf_result="RPi3/${ovmf_target}_GCC/FV/RPI_EFI.fd"
		ovmf_filename="RPI_EFI.fd"
	;;
	rpi4)
		ovmf_arch="AARCH64"
		ovmf_cross_pkg="aarch64-none-elf-gcc"
		ovmf_args="$ovmf_args -D X64EMU_ENABLE=FALSE -D CAPSULE_ENABLE=FALSE"
		ovmf_platfile="Platform/RaspberryPi/RPi4/RPi4.dsc"
		ovmf_result="RPi4/${ovmf_target}_GCC/FV/RPI_EFI.fd"
		ovmf_filename="RPI_EFI.fd"
	;;
	xen_x64)
		only_compile_on="amd64"
		only_compile_on_reason="do not compile on hardware other than amd64"

		ovmf_arch="X64"
		ovmf_platfile="OvmfPkg/OvmfXen.dsc"
		ovmf_result="OvmfXen/${ovmf_target}_GCC/FV/OVMF.fd"
		ovmf_filename="XEN_X64_EFI.fd"
	;;
	bhyve)
		only_compile_on="amd64"
		only_compile_on_reason="Bhyve only runs on x64"

		ovmf_arch="X64"
		ovmf_args="$ovmf_args -D SECURE_BOOT_ENABLE=TRUE -D TPM2_ENABLE=TRUE"
		ovmf_platfile="OvmfPkg/Bhyve/BhyveX64.dsc"
		ovmf_result="BhyveX64/${ovmf_target}_GCC/FV/BHYVE.fd"
		ovmf_result_code="BhyveX64/${ovmf_target}_GCC/FV/BHYVE_CODE.fd"
		ovmf_result_vars="BhyveX64/${ovmf_target}_GCC/FV/BHYVE_VARS.fd"
		ovmf_filename="BHYVE_UEFI.fd"
		ovmf_filename_code="BHYVE_UEFI_CODE.fd"
		ovmf_filename_vars="BHYVE_UEFI_VARS.fd"
		#	patchfiles="ffce430d2b65d508a1604dc986ba16db3583943d.patch:-p1"
	;;
	qemu_x64)
		only_compile_on="amd64"
		only_compile_on_reason="Do not compile on hardware other than amd64"

		ovmf_arch="X64"
		ovmf_platfile="OvmfPkg/OvmfPkgX64.dsc"
		ovmf_result="OvmfX64/${ovmf_target}_GCC/FV/OVMF.fd"
		ovmf_result_code="OvmfX64/${ovmf_target}_GCC/FV/OVMF_CODE.fd"
		ovmf_result_vars="OvmfX64/${ovmf_target}_GCC/FV/OVMF_VARS.fd"
		ovmf_filename="QEMU_UEFI-x86_64.fd"
		ovmf_filename_code="QEMU_UEFI_CODE-x86_64.fd"
		ovmf_filename_vars="QEMU_UEFI_VARS-x86_64.fd"
	;;
	qemu_i386|qemu_x86)
		only_compile_on="amd64"
		only_compile_on_reason="Do not compile on hardware other than amd64"

		ovmf_arch="IA32"
		ovmf_platfile="OvmfPkg/OvmfPkgIa32.dsc"
		ovmf_result="OvmfIa32/${ovmf_target}_GCC/FV/OVMF.fd"
		ovmf_result_code="OvmfIa32/${ovmf_target}_GCC/FV/OVMF_CODE.fd"
		ovmf_result_vars="OvmfIa32/${ovmf_target}_GCC/FV/OVMF_VARS.fd"
		ovmf_filename="QEMU_UEFI-i386.fd"
		ovmf_filename_code="QEMU_UEFI_CODE-i386.fd"
		ovmf_filename_vars="QEMU_UEFI_VARS-i386.fd"
	;;
	*)
		err="resolve ovmf_plat"
		return 1
	;;
esac

case "$ovmf_arch" in
	X64|IA32)
		dependencies="$dependencies nasm acpica-tools"
	;;
	AARCH64|RISCV64)
		dependencies="$dependencies dtc"
	;;
esac

## set uname_fmt
if [ "$(uname -p)" = amd64 ]; then
	uname_fmt="X64"
elif [ "$(uname -p)" = i386 ]; then
	uname_fmt="IA32"
else
	uname_fmt="$(uppercase $(uname -p))"
fi

case "$ovmf_arch" in
	"$uname_fmt")
		dependencies="$dependencies gcc$gcc_native_version"
		CC="$(command -v gcc$gcc_native_version)"
		CXX="$(command -v gcc$gcc_native_version)"
		AR="$(command -v gcc-ar$gcc_native_version)"
		NM="$(command -v gcc-nm$gcc_native_version)"
		RANLIB="$(command -v gcc-ranlib$gcc_native_version)"
	;;
	AARCH64)
		dependencies="$dependencies $ovmf_cross_pkg"
		GCC_AARCH64_PREFIX="aarch64-none-elf-"
		CC="$(command -v aarch64-none-elf-gcc)"
		CXX="$(command -v aarch64-none-elf-g++)"
		AR="$(command -v aarch64-none-elf-ar)"
		NM="$(command -v aarch64-none-elf-nm)"
		RANLIB="$(command -v aarch64-none-elf-ranlib)"
	;;
	RISCV64)
		dependencies="$dependencies $ovmf_cross_pkg"
		GCC_RISCV64_PREFIX="riscv64-none-elf-"
		CC="$(command -v riscv64-none-elf-gcc)"
		CXX="$(command -v riscv64-none-elf-g++)"
		AR="$(command -v riscv64-none-elf-ar)"
		NM="$(command -v riscv64-none-elf-nm)"
		RANLIB="$(command -v riscv64-none-elf-ranlib)"
	;;
	*)
		echo "sorry, cannot compile X64/IA32 EDK2 from a different architecture." 1>&2
		err="ovmf_arch_not_compatible"
		return 1
	;;
esac

# create the shim directory
if [ ! -d "$shim_dir" ]; then
	mkdir -p "$shim_dir"
	ln -sf $(command -v gmake) "$shim_dir/make"
	ln -sv "$CC" "$shim_dir/gcc"
	ln -sv "$CXX" "$shim_dir/g++"
	ln -sv "$AR" "$shim_dir/gcc-ar"
	ln -sv "$NM" "$shim_dir/gcc-nm"
	ln -sv "$RANLIB" "$shim_dir/gcc-ranlib"
fi

cat << EOL
ovmf_args (make)   :: ${ovmf_args:-[none]}
ovmf_plat (make)   :: ${ovmf_plat:-[none]}
ovmf_target (make) :: ${ovmf_target:-[none]}
ovmf_arch          :: ${ovmf_arch:-[none]}
ovmf_platfile      :: ${ovmf_platfile:-[none]}
ovmf_result        :: ${ovmf_result:-[none]}
ovmf_result_code   :: ${ovmf_result_code:-[none]}
ovmf_result_vars   :: ${ovmf_result_vars:-[none]}
ovmf_filename      :: ${ovmf_filename:-[none]}
ovmf_filename_code :: ${ovmf_filename_code:-[none]}
ovmf_filename_vars :: ${ovmf_filename_vars:-[none]}

dependencies       :: ${dependencies:-[none]}

CC                 :: ${CC:-[none]}
CXX                :: ${CXX:-[none]}
AR                 :: ${AR:-[none]}
NM                 :: ${NM:-[none]}
RANLIB             :: ${RANLIB:-[none]}
EOL
