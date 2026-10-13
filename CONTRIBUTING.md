# Contributing

## Do you have a question?

GitHub Issues are used for bug reports and new features.

Please ask questions about how to use the library on
[Stack Overflow](https://stackoverflow.com/questions/tagged/rgeo).

## Did you find a bug?

* Ensure the bug was not already reported by searching [Issues](https://github.com/rgeo/rgeo/issues).

* If you're unable to find an open issue addressing the problem,
[open a new one](https://github.com/rgeo/rgeo/issues).
Be sure to include a title and clear description, as much relevant information as possible,
and a code sample demonstrating the expected behavior that is not occurring.

## Did you fix a bug or add a feature?

* Open a new GitHub pull request with the patch.

* Ensure the PR description clearly describes the problem and solution.
Include the relevant issue number if applicable.

* Add an entry to `History.md` describing your contribution.

* Ensure the pull request's CI checks pass. Fork contributions may require a
maintainer to approve the GitHub Actions run before checks can start.

## How to set up a development environment:

##### Fork the repo:

Fork the repository on GitHub, then clone your fork and add the original repository as upstream:

```sh
git clone git@github.com:YOUR_USERNAME/rgeo.git
cd rgeo
git remote add upstream https://github.com/rgeo/rgeo.git
```

##### Install gem dependencies:

```sh
bundle install
```

##### Install Geos (optional)

(OSX)
```sh
brew install geos
```

(Ubuntu)
```sh
apt-get install libgeos-dev
```

##### Make sure the tests pass:

```sh
bundle exec rake
```

If you are working on the C extension, consider setting MAINTAINER_MODE=1 to
have extra information when compiling.

##### Check that your code style is OK

```sh
bundle exec rubocop
bin/clang-format lint
```
