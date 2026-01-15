# Custom completion for the age command only if 'age' is available
if (( $+commands[age] )); then
  function _age_completion {
    local state curcontext="$curcontext" ret=1

    _arguments -C \
      '--encrypt[Encrypt the input to the output. Default if omitted]' \
      '--decrypt[Decrypt the input to the output]' \
      '--output=[Write the result to the file at path OUTPUT]:output file:_files' \
      '--armor[Encrypt to a PEM encoded format]' \
      '--passphrase[Encrypt with a passphrase]' \
      '--recipient=[Encrypt to the specified RECIPIENT. Can be repeated]:recipient:_files' \
      '--recipients-file=[Encrypt to recipients listed at PATH. Can be repeated]:recipients file:_files' \
      '--identity=[Use the identity file at PATH. Can be repeated]:identity file:_files' \
      '*: :_files' && ret=0

    return ret
  }

  # Register the completion function
  compdef _age_completion age
fi

