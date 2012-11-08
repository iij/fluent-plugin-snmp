# Fluent::Plugin::Snmp

Fluent plugin from snmp

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-snmp'

And then execute:

    $ bundle

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
      nodes name, value                                                 
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

## Copyright
Copyright (c) 2012 Internet Initiative Inc.
Apache Licence, Version 2.0
