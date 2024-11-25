# terraform
if ! terraform_loc="$(type -p "$terraform")" || [[ -z $terraform_loc ]]; then
  alias tf="terraform"
fi
