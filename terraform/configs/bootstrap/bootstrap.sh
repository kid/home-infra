#!/usr/bin/env bash

set -eu

(
	# Make sure we move into the stack's folder in
	# case the script is called from somewhere else
	cd "${BASH_SOURCE%/*}" || exit

	config=$(cat ./terraform.tfvars.json)

	location="$(echo "$config" | jq -r .location)"
	resource_group_name="$(echo "$config" | jq -r .resource_group_name)"
	storage_account_name="$(echo "$config" | jq -r .storage_account_name)"
	container_name="$(echo "$config" | jq -r .container_name)"

	az group create \
		--name "$resource_group_name" \
		--location "$location"
	az storage account create \
		--resource-group "$resource_group_name" \
		--name "$storage_account_name" \
		--sku "Standard_LRS"
	az storage container create \
		--name "$container_name" \
		--account-name "$storage_account_name"

	terragrunt apply
)
