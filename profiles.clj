{:user
 {:plugins [[cider/cider-nrepl "0.9.1"]]
  :dependencies [[org.clojure/tools.nrepl "0.2.10"]]
  :repl-options
    {:init
     (do (load-file (str (System/getenv "HOME") "/dev/clojure/lib/gws/src/repl.clj"))
         (require '[gws.repl :as u]))}}}
