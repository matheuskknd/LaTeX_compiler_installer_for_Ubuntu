#!/bin/bash

#Full documentation can be found at: https://www.tug.org/texlive/doc/texlive-en/texlive-en.html#x1-20001

function close(){

	echo -e "\n################################"
	echo -e "Finishing script now...\n"

exit -1;}


function know_command(){

	if [ -n "$(whereis $1 | cut -d':' -f2)" ] ; then return 0; fi

return -1;}


function add_to_sudo(){

	if [ ! -d "$1" ] ; then return 1; fi

	sudo chown --recursive 0 "$1"
	sudo chmod --recursive 755 "$1"

	local file_name; local original; local temp; local aux; local all;

	file_name=".temp_bash_$RANDOM"
	sudo cat '/etc/sudoers' >$file_name

	################################

	original="$( cat $file_name | grep 'secure_path')"	#original line...

	if [[ "$original" =~ "$1" ]] ; then rm $file_name; return 2; fi	#Already has...

	################################

	aux="${original::(-1)}:$1\""
	aux="secure_path=${aux#*secure_path=}"

	################################

	all="$( cat $file_name)"

	original="secure_path${original#*secure_path}"

	temp="${all%secure_path*}"
	all=${all:(( ${#temp} + ${#original} ))}

	echo "$temp""$aux""$all" >$file_name

	if ! sudo visudo -q -s -c -f $file_name ; then rm $file_name; return 4; fi	#Checking validation of new file...

	################################

	unset original; unset temp; unset aux; unset all;

	sudo chown 0 $file_name
	sudo chmod 700 $file_name

	if ! sudo mv $file_name '/etc/sudoers' ; then rm $file_name; return 8; fi	#Checks if the move was well-succeed

return 0;}


function main(){

	################ Checking Installation ################

	if know_command 'makeindex' || know_command 'pdflatex' || know_command 'texlive' || know_command 'bibtex' || know_command 'tlmgr' ; then

		echo "It seems you already have some TexLive stuff installed like pdflatex, bibtex, tlmgr..."
		echo "If you want to reinstall it from zero, please, remove all previous versions of it and run this script again..."
		close;
	fi

	################ Checking Privileges ################

	if (( "$EUID" != 0 )) ; then

		echo -e "This script may only be executed from super users, once it has to install several things..."
		close;
	fi

	################ Getting into working dir ################

	if [ ! -d 'TexLive_Download_Stuff' ] ; then mkdir 'TexLive_Download_Stuff'; fi
	sudo chmod -R 700 'TexLive_Download_Stuff'
	cd 'TexLive_Download_Stuff'

	################ Getting TexLive installer from CTAN repository ################

	if ! know_command 'wget' ; then

		sudo apt-get install wget
	fi

	if [ ! -e 'install-tl-unx.tar.gz' ] ; then

		wget -O 'install-tl-unx.tar.gz' 'http://linorg.usp.br/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz'
	fi

	if [ ! -e 'install-tl-unx.tar.gz' ] ; then

		echo "File couldn't be downloaded... Try to download from http://linorg.usp.br/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz, put into the new dir and run it again."
		close;
	fi

	################ Uncompressing ################

	if ! know_command 'tar' ; then

		sudo apt-get install tar
	fi

	if ! tar -xf 'install-tl-unx.tar.gz'; then

		echo "File install-tl-unx.tar.gz couldn't be uncompressed, try to uncompress it your self and try to run it again."
		close;
	fi

	################ Getting File name ################

	local dir_name;	#Contains the correct directory name...
	local dir_year;	#Contains the correct directory year...

	local aux=$(ls);
	local i;

	for i in ${aux[@]} ; do

		if [[ "$i" =~ ^install-tl-20.{6}$ ]] ; then

			dir_name="$i";
			break;
		fi
	done

	dir_year="${dir_name#install-tl-}";
	dir_year="${dir_year::(-4)}";

	unset aux; unset i;

	################ Openning Installation GUI ################

	if [[ ! "$(dpkg -s perl-tk 2>/dev/null)" =~ "ok installed" ]] ; then

		sudo apt-get install perl-tk
	fi

	echo -e "\n################################################################"
	echo "Important warning: install this program in all the default directories it suggests."
	echo "Otherwise this script won't be able to help finishing installation."
	echo "Press enter to continue..."

	read -s aux; unset aux;
	echo ''

	cd "$dir_name"
	sudo perl 'install-tl' -gui
	cd ..

	################ Pos-installation procedures ################

	local TexLive_BD='';

	if [ -d "/usr/local/texlive/$dir_year/bin" ] ; then

		TexLive_BD="/usr/local/texlive/$dir_year/bin"
		TexLive_BD="$TexLive_BD/""$(ls $TexLive_BD)"
	fi

	if [ -d "$TexLive_BD" ] ; then

		################ Configurating system to find installation ################

		add_to_sudo "$TexLive_BD"; #Does not fails if already has...

		aux=$(cat '/etc/environment');
		local changed_environment=false;

		if [[ ! "$aux" =~ "$TexLive_BD" ]] ; then

			aux="${aux//'"'/}";
			aux="${aux#*=}";

			aux="$aux:$TexLive_BD"

			local aux_file=".bash_temp_$RANDOM.txt";

			echo 'PATH="'"$aux"\" >"$aux_file"
			sudo mv "$aux_file" '/etc/environment'

			changed_environment=true;
		fi

		if [[ ! "$INFOPATH" =~ "/usr/local/texlive/$dir_year/texmf-dist/doc/info" ]] ; then

			aux="$INFOPATH:/usr/local/texlive/$dir_year/texmf-dist/doc/info"
			local INFOPATH="$aux"
			export INFOPATH
		fi

		if [[ ! "$MANPATH" =~ "/usr/local/texlive/$dir_year/texmf-dist/doc/man" ]] ; then

			aux="$MANPATH:/usr/local/texlive/$dir_year/texmf-dist/doc/man"
			local MANPATH="$aux"
			export MANPATH
		fi

		if [ $changed_environment == true ] ; then

			local restart;
			echo -e -n "\nDo you want to restart your computer to apply changes in /etc/environment file? yes(y)/no(n): "
			read restart

			if [[ "$restart" =~ ^[yY]$ ]] ; then

				cd ..
				sudo chmod -R 777 'TexLive_Download_Stuff'
				sudo reboot now & exit 0
			fi

			if [[ ! "$restart" =~ ^[nN]$ ]] ; then echo "Unknown option..."; fi

			echo "Don't forget to restart your computer manually for the installation to take effect."
		fi
	else

		echo "Installation unsuccessful..."
	fi

	cd ..
	sudo chmod -R 777 'TexLive_Download_Stuff'

	echo -e "\n#################################"
	echo -e "Finishing script normally...\n"

return 0;}

main
