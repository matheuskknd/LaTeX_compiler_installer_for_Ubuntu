#!/bin/bash

#The original procedure was caught from here:
: << 'this_is_comment'

#From: https://www.vivaolinux.com.br/script/Compilar-latex-e-gerar-pdf

#!/bin/bash
# tex_gen_pdf.sh 
# função: Executar os comandos latex, bibtex e makeindex de forma simplificada
# autor: Ricardo Brito do Nascimento britodfbr<at>incolume.com.br
# exemplo: tex_gen_pdf.sh <arquivo>


function tex(){
	pdflatex --interaction=nonstopmode $1
	pdflatex --interaction=nonstopmode $1
	bibtex $(basename $1 .tex)
	pdflatex --interaction=nonstopmode $1
	bibtex $(basename $1 .tex)
	makeindex $(basename $1 .tex).glo -s $(basename $1 .tex).ist -t $(basename $1 .tex).glg -o $(basename $1 .tex).gls
	makeindex -s $(basename $1 .tex).ist -t $(basename $1 .tex).nlg -o $(basename $1 .tex).ntn $(basename $1 .tex).not

	pdflatex --interaction=nonstopmode $1
	bibtex $(basename $1 .tex)
	makeindex $(basename $1 .tex).glo -s $(basename $1 .tex).ist -t $(basename $1 .tex).glg -o $(basename $1 .tex).gls
	makeindex -s $(basename $1 .tex).ist -t $(basename $1 .tex).nlg -o $(basename $1 .tex).ntn $(basename $1 .tex).not

	pdflatex --interaction=nonstopmode $1
	pdflatex --interaction=nonstopmode $1
	pdflatex --interaction=nonstopmode $1
	[ -e $(basename $1 .tex).pdf ] && evince $(basename $1 .tex).pdf&
}
tex $@

this_is_comment

#Global variables:
	aux_dir='' #defined on main

function close(){

	echo -e "\n#################################"
	echo -e "Finishing script now...\n"

exit -1;}


function pdflatex_command(){

	local aux=$( pdflatex -no-shell-escape -interaction=nonstopmode -file-line-error -halt-on-error --output-directory="$aux_dir" "$1"  );

	if [[ ! "$aux" =~ "Fatal" ]] ; then return 0; fi

	aux="./$1:${aux#*$1:}";

	echo -n "${aux%Transcript*}";

return -1;}


function bibtex_command(){ bibtex -terse "$1"; return "$?"; }


function Latex_to_PDF(){

	local file_name=$(basename $1 .tex);

	local made_indexes=1;
	local citaions=1;

	if [ -e "$file_name.glo" ] || [ -e "$file_name.ist" ] || [ -e "$file_name.glg" ] || [ -e "$file_name.gls" ] ; then made_indexes=0; fi
	if [ -n "$(grep '\citation' $1)"  ] || [ -n "$(grep '\bibdata' $1)"  ] || [ -n "$(grep '\bibstyle' $1)"  ] ; then citaions=0; fi

	if

	pdflatex_command "$1" &&
	pdflatex_command "$1" &&
	( (( $citaions != 0 )) || bibtex_command "$file_name" ) &&

	pdflatex_command "$1" &&
	( (( $citaions != 0 )) || bibtex_command "$file_name" >&- ) &&

	( (( $made_indexes != 0 )) || (

		makeindex "$file_name.glo" -s "$file_name.ist" -t "$file_name.glg" -o "$file_name.gls" &&
		makeindex -s "$file_name.ist" -t "$file_name.nlg" -o "$file_name.ntn" "$file_name.not"

	)) &&

	pdflatex_command "$1" &&
	( (( $citaions != 0 )) || bibtex_command "$file_name" >&- ) &&

	( (( $made_indexes != 0 )) || (

		makeindex "$file_name.glo" -s "$file_name.ist" -t "$file_name.glg" -o "$file_name.gls" &&
		makeindex -s "$file_name.ist" -t "$file_name.nlg" -o "$file_name.ntn" "$file_name.not"

	)) &&

	pdflatex_command "$1" &&
	pdflatex_command "$1" &&
	pdflatex_command "$1" &&

	[ -e "$aux_dir/$file_name.pdf" ] ; then

		return 0;
	fi

return -1;}


function main(){

	if [ -z "$(whereis pdflatex | cut -d':' -f2)" ] || [ -z "$(whereis bibtex | cut -d':' -f2)" ] || [ -z "$(whereis makeindex | cut -d':' -f2)" ] ; then

		{
			echo -e "\nIt seems you don't actually have a LaTeX compiler installed!"
			echo -e "Execute the following scritp on your terminal and try to run this one again:\n"

			echo -e "sudo ./Install_TexLive_Ubuntu.sh";

		} >&2

		close;
	fi


	local file_dir="${1%/$(basename $1)}";
	if [ -d $file_dir ] ; then cd $file_dir; fi

	local file_name="$(basename $1)";	#Has .tex at end...

	aux_dir="${file_name%.tex}_compiling_aux_info";

	if [ ! -d "$aux_dir" ] ; then mkdir "$aux_dir"; fi

	Latex_to_PDF "$file_name";
	local worked="$?";

	if (( "$worked" == 0 )) ; then

		local pdf_name="${file_name%.tex}.pdf";

		rm -rf "$aux_dir/${file_name%.tex}.log"
		mv "$aux_dir/$pdf_name" "$pdf_name"

		$(evince "$pdf_name" >&2 2>&-) &
		return 0;
	fi

return -1;}

f_name="${1// /?}"

if (( "$#" < 1 )) || (( "$#" > 1 )) ; then

	echo -e "\nTry again passing one parameter!\n";
else

	if [ -e $f_name ] && [ -z ${f_name#*.tex} ] ; then main "$f_name"; exit "$?"; fi

	echo -e "\nThe parameter must to be an existing file with name ending on '.tex'\n";
fi
