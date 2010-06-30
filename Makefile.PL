use inc::Module::Install;

name    'SimpleStorage';
abstract    'simple, small, asynchronous storage modules';
author      'Joshua Thayer <joshuamilesthayer@gmail.com>';
version     '0.01';
license     'perl';

requires    'IO::AIO';
requires    'JSON';

WriteAll;
