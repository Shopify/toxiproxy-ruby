# Release

## Before You Begin

Ensure your local workstation is configured to be able to
[Sign commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

## Local Release Preparation

### Checkout latest code

```shell
$ git checkout master
$ git pull origin master
```

### Bump version

Update version in [`lib/toxiproxy/version.rb`](./lib/toxiproxy/version.rb).
Check if there is required changes in [`README.md`](./README.md).

### Run Tests

Make sure all tests passed and gem could be build

```shell
$ rake test
$ rake build
```

### Create Release Commit and Tag

Commit changes and create a tag. Make sure commit and tag are signed.

```shell
$ export RELEASE_VERSION=2.x.y
$ git commit -a -S -m "Release $RELEASE_VERSION"
$ git tag -s "v$RELEASE_VERSION"
```

## Release Tag

On your local machine again, push your tag to the repository.

```shell
$ git push origin "v$RELEASE_VERSION"
```

and only after push changes in `master`:

```shell
$ git push origin master
```

## Verify rubygems release

- Shipit should kick off a build and release after new version detected.
- Check [rubygems](https://rubygems.org/gems/toxiproxy)

## Github release

- Create a new gem
    ```shell
    $ bundle exec rake build
    ```
- Create github release. Choose either `hub` or `gh`.
  * Github CLi [gh_release_create](https://cli.github.com/manual/gh_release_create) :
    ```
    $ gh release create v<version> pkg/toxiproxy-<version>.gem
    ```
  * Hub:
    ```
    $ hub release create -a pkg/toxiproxy-<version>.gem v<version>
    ```
