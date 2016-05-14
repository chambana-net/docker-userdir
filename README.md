docker-userdir
==============
A variant of [docker-jekyll-github](https://github.com/chambana-net/docker-jekyll-github) that in addition to serving a static site, provides mod_userdir directory and SSH support.

Usage
-----
See [docker-jekyll-github](https://github.com/chambana-net/docker-jekyll-github) for configuration options related to pulling Jekyll sites from Github repositories.

Besides the above functionality, this container provides user creation and SSH support, and hosts user pages on port 80 from `$HOME/public_html` as per the standard functionality of Apache mod_userdir. In order to use this support, create a `users.yml` file and mount it as a volume into the directory at `/etc/ssh/auth/users.yml`. This will be used to create users when the container starts up. The YAML file has the format:

```
foo:
  key: bar
baz:
  key: qux
```

Which creates the users `foo` and `bar`, and where they keys provided are full SSH public key strings such as would be contained in an `authorized_keys` file. An example docker-compose stanza:

```
example-com:
    image: chambana/userdir
    ports:
      - "2222:22"
      - "80:80"
    volumes:
      - /root/users.yml:/etc/ssh/auth/users.yml:ro
      - /var/users:/home
    environment:
      - GITHUB_USER=example
      - GITHUB_REPO=example.com
```
This example downloads and builds a Jekyll site from the 'example.com' project owned by user 'example', mounts the `/var/users` directory from the host to serve as user home directories inside the container, and exposes SSH on port 2222 and Apache on port 80. If `users.yml` was as above and this host was reachable at `example.com`, `foo` would be able to login via SSH on port 2222 to host `example.com`, and files placed in `/home/foo/public_html` in the container would be accessible at `http://example.com/~foo/`.

Tips
----
* The YAML parsing is just a bash function and is not rigorous! *Use two spaces for tabs for best results.*
* For SSL support it is recommented to run this behind a proxy setup.
