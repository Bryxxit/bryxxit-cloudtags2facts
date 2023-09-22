# cloudtags2facts

Welcome to the `cloudtags2facts` module.

This module will take any of your cloudcompute tags and represent them as individual facts in Puppet.

## Supported Cloud platforms
- AWS
- Azure
- OCI
- GCE

## Setup

### What cloudtags2facts affects **OPTIONAL**

If it's obvious what your module touches, you can skip this section. For
example, folks can probably figure out that your mysql_instance module affects
their MySQL instances.

If there's more that they should know about, though, this is the place to
mention:

* Files, packages, services, or operations that the module will alter, impact,
  or execute.
* Dependencies that your module automatically installs.
* Warnings or other important notices.

### Setup Requirements **OPTIONAL**

No specific setup is required to use this module.

### Beginning with cloudtags2facts

Just add this module to your control repository and let plugin sync take care of the rest.


## Usage

The module uses each clouds internal APIs so there is no need to add any cloud specific credentials to your Puppet/Hiera code. 

The generated facts use are buildup as follows:
    - `tag_` as a prefix
    - `tag_name` 
    - `tag_value` as the value of the fact itself

eg. `tag_role: "webserver"` reads the role tag on your node (which has a value of `webserver`) and represents is as the `tag_role` fact.
