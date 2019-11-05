#!/bin/bash
CONF=/var/rudder/configuration-repository
CATEGORY=bob
TECH=a

cd $CONF
git reset

# 50_techniques
mkdir -p $CONF/ncf/50_techniques/$CATEGORY/$TECH
touch $CONF/ncf/50_techniques/$CATEGORY/$TECH/$TECH.cf
chown -R ncf-api-venv:rudder $CONF/ncf/50_techniques/$CATEGORY
chmod 664 -R $CONF/ncf/50_techniques/$CATEGORY

# techniques/CATEGORY
mkdir -p $CONF/techniques/$CATEGORY/$TECH
cat <<EOT > $CONF/techniques/$CATEGORY/category.xml
<xml>
  <name>$CATEGORY</name>
  <description>
    Techniques from the CIS plugin
  </description>
</xml>
EOT
chown -R ncf-api-venv:rudder $CONF/techniques/$CATEGORY
chmod 664 -R $CONF/techniques/$CATEGORY

# techniques/ncf_techniques
mkdir -p $CONF/techniques/ncf_techniques/$CATEGORY
cd $CONF/techniques/ncf_techniques/$CATEGORY && ln -nrsf ../../$CATEGORY/$TECH && cd -
chown -R ncf-api-venv:rudder $CONF/techniques/ncf_techniques/$CATEGORY
chmod 664 -R $CONF/techniques/ncf_techniques/$CATEGORY


# Commit
chmod -R +X $CONF
git add $CONF/ncf/50_techniques/$CATEGORY $CONF/techniques/$CATEGORY $CONF/techniques/ncf_techniques/$CATEGORY
git commit -m "Importing op technique"
rudder server reload-techniques

# Import techniques

cat <<EOT > /tmp/$TECH.json
{
  "data": {
    "bundle_args": [
      "service"
    ],
    "bundle_name": "a",
    "description": "",
    "method_calls": [
      {
        "args": [
          "skip_item_\${report_data.canonified_directive_id}",
          "node.properties[skip][\${report_data.directive_id}]"
        ],
        "class_context": "any",
        "component": "condition_from_variable_existence",
        "method_name": "condition_from_variable_existence"
      },
      {
        "args": [
          "\${service}"
        ],
        "class_context": "any.(skip_item_\${report_data.canonified_directive_id}_false)",
        "component": "service_enabled",
        "method_name": "service_enabled"
      },
      {
        "args": [
          "\${service}"
        ],
        "class_context": "any.(skip_item_\${report_data.canonified_directive_id}_false)",
        "component": "service_started",
        "method_name": "service_started"
      }
    ],
    "name": "Enable Service",
    "parameter": [
      {
        "constraints": {
          "allow_empty_string": false,
          "allow_whitespace_string": false,
          "max_length": 16384
        },
        "id": "981a5b9d-b062-4011-8dff-df1810cb2fe6",
        "name": "service"
      }
    ],
    "version": "1.0"
  },
  "tags": [],
  "type": "ncf_technique",
  "version": 1
}
EOT

mkdir /usr/share/rudder-api-client
cd /tmp
git clone https://github.com/Normation/rudder-api-client.git
cd rudder-api-client/lib.python && ./build.sh && mv rudder.py /usr/share/rudder-api-client/rudder.py
wget https://raw.githubusercontent.com/Normation/rudder-plugins/master/cis/packaging/rudder-synchronize -O /tmp/rudder-synchronize
chmod +x /tmp/rudder-synchronize
/tmp/rudder-synchronize import technique /tmp/$TECH.json
