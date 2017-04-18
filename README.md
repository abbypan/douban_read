# douban_read
download book from https://read.douban.com/  豆瓣阅读

# install

perl, calibre, firefox, firefox addon: mozrepl

    $ cpan App::cpanminus
    $ cpanm WWW::Mechanize::Firefox
    $ cpanm Web::Scraper
    $ cpanm Novel::Robot
    $ cpanm Encode::Locale

# usage

perl douban_read.pl [first chapter url of the book]


例如，下载 [飘灯-相国](https://read.douban.com/reader/column/1519073/chapter/9109225/)，转换成 txt/html/mobi 三种格式

    $ perl douban_read.pl https://read.douban.com/reader/column/1519073/chapter/9109225/ | tee book.log

