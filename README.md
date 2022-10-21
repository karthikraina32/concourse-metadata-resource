# concourse-metadata-resource
This resource outputs [Concourse-ci](https://concourse-ci.org/) [build metadata](https://concourse-ci.org/implementing-resource-types.html#resource-metadata)
to files to make annotations easier.  
How it is better from other resources, because this metadata resource has the info of how have triggered the build

### `check`: Not used
Always emits an empty version.

### `in`: Output metadata to files
Outputs `$BUILD_ID`, `$BUILD_NAME`, `$BUILD_JOB_NAME`, `$BUILD_PIPELINE_NAME`, `$BUILD_TEAM_NAME` `$ATC_EXTERNAL_URL` and `$BUILD_CREATED_BY` to files `build_id`, `build_name`, `build_job_name`, `build_pipeline_name`, `build_team_name`, `atc_external_url` and `build_created_by` respectively.

### `out`: Passing BUILD_CREATED_BY value to version
`$BUILD_CREATED_BY` is passed as version from put step to get step, reason `$BUILD_CREATED_BY` hasn't been set as environment variable in get step

## Example
The following example shows how to use this resource and send the slack notification of who have triggered the build

```yaml
# Register the metadata resource type
resource_types:
  - name: metadata
    type: docker-image
    source:
      repository: karthikkumar268/concourse-metadata-resource
      tag: v1.0

resources:
  - name: metadata
    type: metadata
    expose_build_created_by: true # this flag is needed to be enabled 

  # GitHub release resource
  # Check https://github.com/concourse/github-release-resource#source-configuration for more info
  - name: git-resource
    type: git
    icon: github
    source:
      uri: https://github.com/<repo_name>
      username: ((username))
      password: ((access-token))


jobs:
  - name: run-build
    plan:
      - put: metadata
      - get: git-resource

      - task: send-slack-notification
        config:
          platform: linux
          image_resource:
            type: docker-image
            source:
              repository: busybox
          inputs:
            - name: metadata
          run:
            path: sh
            args:
              - -exc
              - |
                # Grab the metadata
                url=$(cat metadata/atc_external_url)
                team=$(cat metadata/build_team_name)
                pipeline=$(cat metadata/build_pipeline_name)
                job=$(cat metadata/build_job_name)
                build=$(cat metadata/build_name)
                build_created_by=$(cat metadata/build_created_by)
                
                # curl to send slack notification
                curl -X POST -H 'Content-type: application/json' --data '{"attachments":[{  "color":"#72C600", "fields":[{ "title":"Success", "value":"latest version of app has been deployed in by '$build_created_by'", "short":false }  ]}  ]}' ${webhook}
```

