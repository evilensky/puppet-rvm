class rvm::rubies {
  $rubies = hiera('rvm_system_ruby')
  create_resources('rvm_system_ruby', $rubies)
}
