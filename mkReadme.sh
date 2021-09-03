#!/bin/bash

README_FILE='./README.md'
FRONTMATTER='./frontmatter.md'
BACKMATTER='./backmatter.md'
SCIENTIFIC_REPOSITORIES='./scientific_repositories'
EDUCATIONAL_REPOSITORIES='./educational_repositories'

CALL_DELAY=0.2

function ask_confirmation {
	declare -i answer
	while true; do
		echo "$1"
		read -p "Continue? (y/n) " yn
		case $yn in
			[Yy]* ) answer=0; break;;
			* ) answer=1; break;;
		esac
	done

	return $answer
}

function create_API_URIs {
	# convert repositories URIs to API URIs and return as indexed array
	declare -n uri_array="$1"
	mapfile -t uri_array < <( sed -r 's|http(s)?://github\.com/(\w+)/(\w+)(/?)|https://api.github.com/repos/\2/\3|g;s|http(s)?://github\.com/(\w+)(/?)|https://api.github.com/orgs/\2|g' "$2" )
}

function retrieve_info {
	# retrieve repository info from API and return JSON output
	declare -r uri="$1"
	echo $( curl -sS "$uri" )
}

function add_github_resources {
	declare -a api_uris
	create_API_URIs api_uris "$1"

	for uri in "${api_uris[@]}"
	do
		repo_info=$( retrieve_info "$uri" )

		name=$( jq -r .name < <( echo "$repo_info") )
		desc=$( jq -r .description < <( echo "$repo_info") )
		link=$( jq -r .html_url < <( echo "$repo_info") )

		if [ -z "$name" ] || [ "$name" = "null" ]
		then
			continue
		fi

		echo "- [$name]($link)" >> "$README_FILE"
		if [ ! -z "$desc" ] && [ "$desc" != "null" ]
		then
			echo -e "\t> *$desc*" >> "$README_FILE"
		fi

		sleep $CALL_DELAY
	done

	echo -e '\n' >> "$README_FILE"
}

function main {
	cat "$FRONTMATTER" > "$README_FILE"
	echo -en '\n' >> "$README_FILE"

	if [ -f "$SCIENTIFIC_REPOSITORIES" ]
	then
		echo -e "### Scientific Resources\n" >> "$README_FILE"
		add_github_resources "$SCIENTIFIC_REPOSITORIES"
	else
		echo "Cannot locate file: $SCIENTIFIC_REPOSITORIES"
	fi

	if [ -f "$EDUCATIONAL_REPOSITORIES" ]
	then
		echo -e "### Educational Resources\n" >> "$README_FILE"
		add_github_resources "$EDUCATIONAL_REPOSITORIES"
	else
		echo "Cannot locate file: $EDUCATIONAL_REPOSITORIES"
	fi

	cat "$BACKMATTER" >> "$README_FILE"
	echo -en "\n---\nList updated on" $(date +%F) >> "$README_FILE"
}

ask_confirmation "This operation will reduce your daily free maximum number of Github API calls."
declare -i answer=$?
if [ $answer -gt 0 ]
then
	exit
fi

if [ -f "$README_FILE" ]
then
	ask_confirmation "README exists. Overwrite $README_FILE ?"
	declare -i answer=$?
	if [ $answer -eq 0 ]
	then
		echo '' > "$README_FILE"
	else
		exit
	fi
else
	touch "$README_FILE"
fi

main
