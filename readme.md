# Nginx test framework



## Run the tests

	sudo make test
or

	sudo make test-vagrant (recommended)

## Exit codes

    0  Everything is OK
    69 There are failed tests
    75 There are no failed tests but there are NOT FOUND tests, meaning that a rule is missing in Nginx

## Adding a test
	
You can add test rules very easy, by adding it to the file test/cases.sh. It is a bash file so you can do anything you can imagine. 

To test a rule you must call 'test_rule' function and especify:

* The method/s (separated by comma ',' or the word 'all' for all methods or 'all_fe' for GET and POST)
* The domain to test you can put the domain in three diferents ways:
** Simple put your domain (example test.mydomain.com)
** Put many domains into '[]' (example [test.mydomain.com,test2.mydomain.com,test3.mydomain.com]
* The url to test
* The target upstream

For example:

    'test_rule GET [www.mydomain.com,test.mydomain.com] / main-upstream

or 

    'test_rule all mobile.mydomain.com / mobile-upstream
   
To test a response status code (e.g. 301 for redirects) you may use the 'test_status' statement.

For example:

    'test_status redirect.mydomain.com / 301 -H "User-Agent:some_undesirable_agent"'

You can find many examples into the 'test/cases.sh'

### Adding POST test  with big content

You can add "test_rule_with_content".

Example:
	test_rule_with_content POST content.mydomain.com /content main-content-upstream 5M

##Adding a Subdomain

All subdomains are in 'subdomains/subdomains.conf' file, you have many examples there.

To add a new subdomain you need to edit 'subdomains/subdomains.conf' 

A simple subdomain example:

    server {
        listen 8080;

        #Url to response
        server_name ~^yourSubdomainRegex$;

        #Default uri
        location / {
            proxy_pass http://Your upstream;
        }
    }
