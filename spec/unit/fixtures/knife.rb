chef_server_url   'http://127.0.0.1:4000'
node_name         'test-node'
client_key        'test_client.pem'
chef_repo_path    'spec/unit/fixtures'
cookbook_path     'spec/unit/fixtures/cookbooks'
cache_options( :path => 'checksums' )