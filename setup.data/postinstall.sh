#!/bin/sh
#
# Fix-ups for Quake 3 Demo install

# The install path is the first argument of the script
install_path="$1"

# Terminal output is redirected during the install process
exec >/dev/tty

# Set up the binary script

# Return the appropriate architecture string
function DetectARCH {
	status=1
	case `uname -m` in
		i?86)  echo "x86"
			status=0;;
		*)     echo "`uname -m`"
			status=0;;
	esac
	return $status
}
arch=`DetectARCH`

function AddToUninstall {
    cmd=""
    if [ -f "$install_path/$1" ]; then
        cmd="rm -f"
    fi
    if [ -d "$install_path/$1" ]; then
        cmd="rmdir"
    fi
    if [ "$cmd" != "" ]; then
        #magic_cookie="#### END OF UNINSTALL"
        magic_cookie="rmdir \"$install_path\""
        sed <"$install_path/uninstall" >"$install_path/uninstall.new" \
            -e "s,$magic_cookie,$cmd \"$install_path/$1\"\\
$magic_cookie,"
        mv "$install_path/uninstall.new" "$install_path/uninstall"
        chmod 755 "$install_path/uninstall"
    fi
}

# Make sure the symlink doesn't prevent pack to be found.
if [ -f "$install_path/q3demo" -a ! -f "$install_path/q3demo.$arch" ]; then
    mv "$install_path/q3demo" "$install_path/q3demo.$arch"
    AddToUninstall q3demo.$arch

    cat <<__EOF__ >"$install_path/q3demo"
#!/bin/sh
# Needed to make symlinks/shortcurts work.
# Run Quake III with some default arguments

cd "$install_path"
quake="./q3demo.$arch"
"\$quake" \$*
exit \$?
__EOF__

    chmod 755 "$install_path/q3demo"
fi

# Set up the MesaGL symbolic links

VoodooGL=libMesaVoodooGL.so.3.2

has_gl=no
if [ -f "$install_path/$VoodooGL" ]; then
    ln -sf $VoodooGL "$install_path/libMesaVoodooGL.so"
    AddToUninstall libMesaVoodooGL.so
    has_gl=yes
fi
if [ "$has_gl" != "yes" ]; then
    echo "Warning: No Voodoo GL libraries were installed"
fi
if [ -f "$install_path/$VoodooGL" ]; then
    ln -sf libMesaVoodooGL.so "$install_path/libGL.so"
    AddToUninstall libGL.so
fi
exit 0
