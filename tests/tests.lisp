(in-package :site-generator-test)
(in-suite :site-generator)

(defvar *test-dir* (merge-pathnames "../tests/"
				    (asdf:component-pathname
				     (asdf:find-system :site-generator))))

(test content
  (let ((*environment* '(:default-language :en
			 :title (:en ("foo") :fr ("bar"))
			 :slug (:fr ("quox")))))
    (is (equal "bar"
	       (sg::get-data :title :fr)))
    (is (equal "foo"
	       (sg::get-data :title)))
    (is (equal nil
	       (sg::get-data :slug :en)))))

(test templates
  (let ((*environment* '(:bar (:en ("baz"))
			 :foo (:en ("$bar$"))
			 :baz (:en ("$foo$"))
			 :markup :none
			 :lang :en)))
   (with-environment
     (is (string= "Foo baz."
		  (expand-string "Foo $bar$.")))
     (is (string= "Foo baz quox."
		  (expand-string "Foo $(concatenate 'string bar \" quox\").")))
     (is (string= "Foo baz."
		  (expand-string "Foo $foo$.")))
     (is (string= "Foo baz."
		  (expand-string "Foo $baz$.")))
     (is (string= "$hi$"
		  (expand-string "\\$hi$")))
     (is (string= "$$"
        	  (expand-string "$$")))
     (is (string= "$x$"
        	  (expand-string "\\$x$")))
     (is (string= "$$"
        	  (expand-string "\\$\\$")))
     (is (string= "$ hello"
		  (expand-string "$ hello")))
     (is (string= "he$bar"
		  (expand-string "he$bar")))
     (is (string= "$hello there$"
		  (expand-string "$hello there$")))
     (is (string= "$hello"
		  (expand-string "\\$hello")))
     (is (string= "\\baz"
		  (expand-string "\\\\$bar$")))
     (is (string= "\\$hello"
		  (expand-string "\\\\\\$hello")))
     (is (string= "\\\\ hello"
		  (expand-string "\\\\ hello")))
     (is (string= "\\\\ baz"
		  (expand-string "\\\\ $bar$"))))))

(test content-parsing
  (is (equal '(:foo)
	     (sg::is-variable? ":foo")))
  (is (equal '(:foo :bar :baz)
	     (sg::is-variable? ":foo bar=baz")))
  (signals simple-error
    (sg::is-variable? ":foo bar"))
  (signals simple-error
    (sg::is-variable? ":foo bar=baz quox"))
  (is (equal
       '(:DEFAULT (:NAV (:MARKUP :MARKDOWN) :CONTENT (:MARKUP :MARKDOWN)) :FOOTER-TEXT
	 (:FR
	  ("Ceci est la fin de la page$(when (bound? title) (echo \" \\\"\" title \"\\\"\")).")
	  :EN
	  ("This is the end of the page$(when (bound? title)
                              (echo \" \" (markup
			                  (echo \"\\\"\" title
			                        \"\\\" (these should be curly quotes)\")
			                  :output-format :markdown
			                  :markup :markdown)))."))
	 :NAV
	 (:FR
	  ("* [Accueil]($(page-address \"index\"))
* [À propos de site-generator]($(page-address \"about\"))
* [Foo]($(page-address \"foo/bar\"))")
	  :EN
	  ("* [Home]($(page-address \"index\"))
* [About site-generator]($(page-address \"about\"))
* [Foo]($(page-address \"foo/bar\"))"))
	 :TEMPLATE "main.html" :LANGUAGES (:EN :FR) :SERVER
	 "alexcharlton@alex-charlton.com:alex-charlton.com/" :SITE-NAME
	 (:EN ("site-generator")))
       (parse-content (merge-pathnames "../examples/example-site/content/config"
				       *test-dir*))))
  (signals simple-error
    (parse-content (merge-pathnames "bad-content1" *test-dir*)))
  (signals simple-error
    (parse-content (merge-pathnames "bad-content2" *test-dir*))))

(test pandoc
  (let ((*environment* '(:output-format :html5 :markup :markdown :toc :true :smart :false)))
    (is (string= "--to=html5 --from=markdown --toc"
		 (sg::generate-pandoc-args '()))))
  (is (string= "<h1 id=\"foo\">foo</h1>"
	       (markup "# foo" :markup :markdown :output-format :html)))
  (let ((*environment* '(:markup :none)))
    (is (string= "foo"
		 (markup "foo")))))

(test site-generator
  (is (equal '(:en #p"foo/bar" :fr #p"lefoo/lebar")
	     (sg::add-slugs '(:en "bar" :fr "lebar")
				      '(:en "foo/" :fr "lefoo/"))))
  (is (equal '(:en #p"bar/" :fr #p"fr/lebar/")
	     (sg::add-slugs '(:en "bar/" :fr "lebar/") '(:en "" :fr "fr/"))))
  (is (equal '(:foo "bar" :default (:content (:markup :markdown)
				    :nav (:markup :markdown :output-format :html5)))
	     (sg::merge-environments '(:default (:nav (:markup :markdown)
						 :content (:markup :markdown)))
				       '(:foo "bar"
					 :default (:nav (:markup :none
							 :output-format :html5))))))
  (is (equal "A_propos_de_site-generator"
	     (sg::slugify  "“À propos de site-generator”")))
  (is (equal "Hello_there_90"
	     (sg::slugify "Hello  there<> 90")))
  (let ((sg::*content-dir* #p""))
    (is (equal '(:en "foo/" :fr "baz/")
	       (sg::get-dir-slugs "foo/config" '(:directory-slug (:fr ("baz"))
						 :languages (:en :fr)))))
   (is (equal '(:en "" :fr "fr/")
	      (sg::get-dir-slugs "config" '(:languages (:en :fr)
					    :default-language :en)))))
  (let ((*environment* '(:languages (:en :fr :gr)
			 :pages-as-directories t
			 :title (:en ("Hello there"))
			 :slug (:fr ("foo")))))
    (is (equal '(:en "Hello_there" :fr "foo" :gr "hello")
	 (sg::get-file-slugs "hello")))
    (is (equal '(:en "foo/index.html" :fr "fr/bar/index.html" :gr "gr/quox/index.html")
	       (sg::get-page-paths "foo" '(:en "foo" :fr "fr/bar" :gr "gr/quox"))))
    (is (equal '(:en "index.html" :fr "fr/index.html" :gr "gr/index.html")
	       (sg::get-page-paths "index"
			      '(:en "index" :fr "fr/index" :gr "gr/index")))))
  (is (equal '(((#P"footer.html" . 3585328073) (#P"other.html" . 3585327838))
		((#P"header.html" . 3586212646))
		((#P"main.html" . 3585328208) (#P"footer.html" . 3585328073)
		 (#P"other.html" . 3585327838)(#P"header.html" . 3586212646))
		((#P"other.html" . 3585327838)))
	     (sg::resolve-template-dependencies
	      '(((#P"footer.html" . 3585328073) (#P"other.html" . 3585327838))
		((#P"header.html" . 3586212646))
		((#P"main.html" . 3585328208) (#P"footer.html" . 3585328073)
		 (#P"header.html" . 3586212646))
		((#P"other.html" . 3585327838)))))))

(test utils
  (is (local-time:timestamp=
       (local-time:encode-timestamp 0 0 0 12 23 4 2013)
       (sg::make-time '(:day 23 :hour 12 :minute 0)
		      (local-time:encode-timestamp 0 0 1 6 2 4 2013))))
  (is (equal '("Foo bar baz" "mu fu shu ich ni san quox quof quafe" "blub blu blub")
	     (sg::escaped-lines "Foo bar baz
mu fu shu\\
ich ni san\\
quox quof quafe
blub blu blub")))
  (is (equal "\\$hi\\$"
	     (escape-dollars "$hi$"))
      (equal "\\\\\\$(hi)\\$"
	     (escape-dollars "\\$(hi)$"))))
