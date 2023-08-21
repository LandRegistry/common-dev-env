echo "Creating Work index"
curl -XPUT "$1/work" -d '{
    "settings" : {
        "number_of_shards" : 1
    },
    "mappings" : {
        "workitem" : {
            "properties" : {
                "worktype" : { "type" : "string" },
                "tag" : { "type" : "string" }
            }
        }
    }
}' > /dev/null 2>&1

echo "Creating Activity index"
curl -XPUT "$1/activities" -d '{
    "settings" : {
        "number_of_shards" : 1
    },
    "mappings" : {
        "activity" : {
            "properties" : {
                "timestamp" : { "type" : "date",
                                              "format": "dateOptionalTime" },
                "reason" : { "type" : "string",
                                      "index": "not_analyzed" }
            }
        }
    }
}' > /dev/null 2>&1