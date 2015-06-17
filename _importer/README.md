# Importing in.relation.to

The scripts in this directory allow you to create required input files to migrate
the exiting in.relation.to blog to awestruct.
The scripts will crawl the site and save all *.lace urls into a Ruby PStore.
From there erb files for the awestruct site can be created. Besides of this the scripts
generate a input file to migrate comments to Disqus as well as redirect files for
old to new URLs.

## How to run the scripts

    # install bundler
    > gem install bundler

    # get your dependencies via bundler
    > bundle install

    # run the crawler
    > bundle exec ./crawler.rb -u http://in.relation.to -p ".*\.lace" -o posts.pstore | tee crawl.log

    # run the importer (creates erb files, Apache redirects and Disqus WXR import file)
    > bundle exec ./importer.rb -s posts.pstore -o ../posts

    # for experiments when you don't want to download images (-ni) and assets (-na)
    > bundle exec ./importer.rb -s posts.pstore -o ../posts -ni -na

## Tips & Tricks

* To nicely format the generated WXR XML file you can use

        xmllint --format --recover <export-file-name>.xml

* When experimenting with the importer it is often nice to start from a clean state. Just run to reset your checkout:

        git clean -f -d

* To list all available script options use '-h'

        > ./crawler.rb -h
        Usage: crawler.rb [-upoh]
        Application options:
        Required:
          -u, --url=<file>                 The base url
          -p, --pattern=<regexp>           Regular expression to limit the discovered pages
          -o, --out=<file>                 The name of the output-file
        Common:
          -h, --help                       Show this message.

        > ./importer.rb -h
        Usage: importer.rb [-sorfwxrelnninah]
        Application options:

            -s, --store=<file>               The PStore file containing the spidered HTML
            -o, --out=<dir>                  The name of the output directory

           -rf, --redirects-file=<file>      The name of file to which write HTTP redirect rules
          -wxr, --wxr-export-file=<file>     The name of WXR XML file. If specified comments are exported, otherwise not

            -e, --log-errors                 Whether failed imports should be logged with stacktrace
            -l, --lace=<lace-url>            Runs the importer only for the given lace url
            -n, --limit=<n>                  Limit the imported posts (for debugging purposes)
           -ni, --no-images                  Wether image processing should be skipped
           -na, --no-assets                  Wether asset processing should be skipped

            -h, --help                       Show this message.

## Resources

* [Bundler](http://gembundler.com/)
* [Encoding problems](http://talk-archive.awestruct.org/Stumbling-onto-an-encoding-problem-right-from-the-start-td39.html)

        incompatible character encodings: ASCII-8BIT and UTF-8

