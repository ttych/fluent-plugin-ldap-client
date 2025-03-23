# fluent-plugin-ldap-client

[Fluentd](https://fluentd.org/) plugin to link with ldap server.

It is plugins that will search data in ldap.

## filter : ldap_enrich

To do enrichment on events through ldap search.

### parameters

Parameters are :

| parameters         | default   | type     | purpose                                                           |
|--------------------|-----------|----------|-------------------------------------------------------------------|
| ldap_host          | localhost | string   | ldap hostname                                                     |
| ldap_port          | 389       | integer  | ldap port                                                         |
| ldap_encryption    | false     | bool     | use tls                                                           |
| ldap_base_dn       | ''        | string   | ldap base DN for query                                            |
| ldap_username      | nil       | string   | username for ldap bind                                            |
| ldap_password      | nil       | string   | password for ldap bind                                            |
| ca_cert            | nil       | string   | path of CA cert                                                   |
| ldap_query         | nil       | string   | query that will be interpolated against record, then sent to ldap |
| ldap_attributes    | {}        | hash     | mapping of ldap attributes to inject in record                    |
| enable_cache       | true      | bool     | enable cache to reduce query to ldap                              |
| cache_size         | 1000      | interger | cache size in number of entries                                   |
| cache_ttl_positive | 24 * 3600 | integer  | ttl of positive entries (not nil) in seconds                      |
| cache_ttl_negative | 3600      | integer  | ttl of negative entries (nil) in seconds                          |

### examples

``` text
<filter test>
  @type ldap_enrich

  ldap_base_dn "dc=test"
  ldap_query "(uid=%{user})"
  ldap_attributes uid:user_uid,mail:user_mail

  cache_enable true
</filter>
```

* use "dc=test" as ldap search base DN
* ldap_query will be interpolated, with %{user} replaced by record['user'], then send the query to ldap
* ldap_attributes will inject uid attributes as user_uid in record, will inject mail attributes as user_mail in record

## Installation

Manual install, by executing:

``` shell
gem install fluent-plugin-ldap-client
```

Add to Gemfile with:

``` shell
bundle add fluent-plugin-ldap-client
```


## Copyright

* Copyright(c) 2025-2025 Thomas Tych
* License
  * Apache License, Version 2.0
