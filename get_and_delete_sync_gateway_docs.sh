#!/bin/bash

##########
# README #
##########

# Make sure you've got the CLI tool `jq` installed
#  ↳ http://stedolan.github.io/jq/ 
# (if you've got homebrew on your Mac just do → `brew install jq`)

# if you want to run the full script and it's not already executable, just do → `chmod +x ./get_and_delete_sync_gateway_docs.sh`

# to run, just do → `./get_and_delete_sync_gateway_docs.sh`

# can hardcode these and comment-out interactive part if you wish
MY_APP_DB_BUCKET="my_app"
MY_SYNC_GATEWAY="http://USERNAME:PASSWORD@my_sync_gateway.com:4984/"

printf "Enter your sync_gateway url w/ trailing slash (e.g. http://127.0.0.1:4984/ or http://USERNAME:PASSWORD@my_sync_gateway.com:4984/): "
read MY_SYNC_GATEWAY

printf "Enter DB/bucket you want to work with: "
read MY_APP_DB_BUCKET

URL_TO_USE="$MY_SYNC_GATEWAY$MY_APP_DB_BUCKET"

ALL_DOCS_FILE="$MY_APP_DB_BUCKET-all_docs.json"
DELETE_THESE_DOCS_FILE="$MY_APP_DB_BUCKET-docs_to_delete.json"

# GET all docs
curl "$URL_TO_USE/_all_docs?include_docs=true" | jq '.' > "$ALL_DOCS_FILE"
printf "\nCreated $ALL_DOCS_FILE"
open "$ALL_DOCS_FILE"

# parse through _all_docs response and format list of URLs to delete them all
cat "$ALL_DOCS_FILE" | jq -r --arg JQ_ARG "$URL_TO_USE" '.rows[].doc | "\($JQ_ARG)/\(._id)?rev=\(._rev)"' > "$DELETE_THESE_DOCS_FILE"
printf "\nCreated $DELETE_THESE_DOCS_FILE"
open "$DELETE_THESE_DOCS_FILE"

printf "\n\nFeel free to make modifications to $DELETE_THESE_DOCS_FILE (and save the file). \nHit 'return' to continue "
read RETURN_ENTERED

# get rid of any leading/trailing whitespace
sed -E -i '' 's/^[ \t]*//;s/[ \t]*$//' "$DELETE_THESE_DOCS_FILE"
# get rid of any blank lines
sed -E -i '' '/./!d' "$DELETE_THESE_DOCS_FILE"

NUMBER_OF_DOCS_TO_DELETE=`cat "$DELETE_THESE_DOCS_FILE" | wc -l`

printf "\nDelete $NUMBER_OF_DOCS_TO_DELETE docs (YES/NO)? "
read SHOULD_DELETE

SHOULD_DELETE=`echo $SHOULD_DELETE | awk '{ print tolower($0) }'`
if [[ $SHOULD_DELETE =~ ^y[e]?[s]? ]]
  then 
		while read LINE; do 
			curl -X DELETE "$LINE"
		done < "$DELETE_THESE_DOCS_FILE"
		printf "\nDone.\n"
	else
		printf "\nOK, nothing was deleted.\n"
fi