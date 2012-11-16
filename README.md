# Fluent::Plugin::Snmp

Fluentd snmp input plugin

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-snmp'

Or install it yourself as:

    $ gem install fluent-plugin-snmp

## Usage

    <source>                                                          
      type snmp                                                         
      tag snmp.server1                                                  
      nodes name, value                                                 
      host server1                                                    
      community private                                                 
      version 2c                                                        
      mib hrStorageIndex, hrStorageDescr, hrStorageSize, hrStorageUsed  
      mib_modules HOST-RESOURCES-MIB                                    
      retries 0                                                         
      timeout 3s                                                        
      polling_time 0,10,20,30,40,50                                     
    </source>                                                         

    <source>                                                          
      type snmp                                                         
      tag snmp.server2                                                  
      host server2                                                    
      community private                                                 
      version 2c                                                        
      mib hrStorageIndex, hrStorageDescr,
      hrStorageSize, hrStorageUsed  
      mib_modules HOST-RESOURCES-MIB                                    
      retries 0                                                         
      timeout 3s                                                        
      polling_time 5,15,25,35,45,55                                     
    </source>                                                         


     2012-11-08 16:07:40 +0900 snmp.server1: {"name":"HOST-RESOURCES-MIB::hrStorageUsed.31","value":"2352425"}         
     2012-11-08 16:07:40 +0900 snmp.server2: {"value":"[name=HOST-RESOURCES-MIB::hrStorageIndex.7, value=7 (INTEGER)]"}  


## Copyright
Copyright (c) 2012 Internet Initiative Inc.
Apache Licence, Version 2.0
