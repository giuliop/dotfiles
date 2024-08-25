;; leiningen
{:user
 {:plugins [[cider/cider-nrepl "0.14.0"]]
  :dependencies [[org.clojure/tools.nrepl "0.2.12"]]
  :repl-options
    {:init
     (do (load-file (str (System/getenv "HOME")
                         "/dev/clojure/lib/gws/src/gws/repl.clj"))
         (require '[gws.repl :as u]))}}}
