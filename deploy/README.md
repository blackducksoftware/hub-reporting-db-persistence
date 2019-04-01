## Deployment files

Deployment of the feature is doe by applying the setup sctipt tothe bds_hub_report database of the target system

This will create pdata schema, duplicate table structures, copy all existing data and generate  triggers.

### Moving forward

Subsequent releases will be applied as patches. E.g. unique_key_patch.psql

## Cleanup script.

Cleanup scriot will tear down persiistennt scema and discard all data it contains.

DO NOT USE IT IN PRODUCTION !!!
