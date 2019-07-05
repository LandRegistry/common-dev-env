def delete_files(root_loc)
  File.delete(root_loc + '/.commodities.yml') if File.exist?(root_loc + '/.commodities.yml')
  File.delete(root_loc + '/.custom_provision.yml') if File.exist?(root_loc + '/.custom_provision.yml')
  File.delete(root_loc + '/.docker-compose-file-list') if File.exist?(root_loc + '/.docker-compose-file-list')
  File.delete(root_loc + '/.after-up-once') if File.exist?(root_loc + '/.after-up-once')
  File.delete(root_loc + '/.db2_init.sql') if File.exist?(root_loc + '/.db2_init.sql')
  File.delete(root_loc + '/.postgres_init.sql') if File.exist?(root_loc + '/.postgres_init.sql')
end
