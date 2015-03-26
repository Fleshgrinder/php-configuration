# PHP configuration
PHP configuration targeting latest stable PHP release.

## Install
```shell
git clone https://github.com/Fleshgrinder/php-configuration.git
make
cp -R * /etc/php
```

### Extensions
```shell
make mongo # FPM + CLI
make xdebug # CLI
```

Have a look at [this PHP manual page](https://php.net/extensions.membership) for 
a listing of available extensions. Pull requests with additional make targets 
are very welcome.

## Usage
The _available_ directory contains several configuration files for 
various dynamic (and compiled in) extensions, as well as configuration files for 
extensions which need to be installed first (check the makefile targets).

You might want to symlink the `fpm.ini` to `php-fpm.conf` if you are not using my 
PHP compiler and init script. The link will be ignored by git.

## Weblinks
Other repositories of interest:
- [php-compile](https://github.com/Fleshgrinder/php-compile)
- [php-fpm-sysvinit-script](https://github.com/Fleshgrinder/php-fpm-sysvinit-script)

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>
