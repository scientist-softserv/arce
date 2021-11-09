[Docker development setup](#docker-development-setup)
[Bash into the container](#bash-into-the-container)
[Deploy a new release](#deploy-a-new-release)
[Clear data records](#clear-data-records)
[Run import from admin page](#run-import-from-admin-page)

# Docker development setup
We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

1) Install Docker.app

2) Install stack car
    ``` bash
    gem install stack_car
    ```

3) Install dory and enable dory
    ``` bash
    gem install dory
    ```

4) Install dependencies
    ``` bash
    sc build
    ```

5) Start dory
    ``` bash
    dory up
    ```

6) Start the server
    ``` bash
    sc up
    ```

7) Load the database
    ``` bash
    sc be rake db:migrate
    ```

8) Import data into the database. The `[100]` limits the number of records to 100. If you want to load more items, increase the number. If you wish to load all items, remove the brackets entirely. If you want to import a specific set, you can pass the set in as the second argument. The default set is 'arce_1', which imports all of the collections.
    ``` bash
    sc exec bash
    rake import[100]
    ```

    To import 100 of the Tomb of Menna collection:
    ```bash
    sc exec bash
    rake import[100,'tom_1']
    ```

9) Then visit http://arce.docker in your browser

10) If you need a user or need to be an admin, load the seed data
    ``` bash
    sc be rake db:seed
    ```

### Troubleshooting Docker Development Setup
Confirm or configure settings. Sub your information for the examples.
``` bash
git config --global user.name example
git config --global user.email example@example.com
docker login registry.gitlab.com
```

# Bash into the container
``` bash
sc exec bash
```

### While in the container you can do the following
- Run rspec
    ``` bash
    bundle exec rspec
    ```
- Access the rails console
    ``` bash
    bundle exec rails c
    ```

# Deploy a new release
``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deploys those tags to the server
```

Release and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image

# Clear data records
``` bash
sc be rake clear
```

# Run import from admin page
Login to admin page using seed user info
Press the import records button

Release and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image
