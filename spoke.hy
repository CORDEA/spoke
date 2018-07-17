#!/usr/bin/env hy
;; Copyright 2018 Yoshihiro Tanaka
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;   http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;
;; Author: Yoshihiro Tanaka <contact@cordea.jp>
;; date  : 2018-07-14

(require [hy.contrib.walk [let]])
(import [argparse [ArgumentParser]])
(import subprocess)

(defn git-ls-files [option]
  (.Popen subprocess (flatten ["git" "ls-files" option]) :stdout subprocess.PIPE))

(defn git-show [&rest option]
  (setv process1 (git-ls-files option))
  (setv files (nth (.communicate process1) 0))
  (.close process1.stdout)
  files)

(defn git-add [&rest option]
  (setv process1 (git-ls-files option))
  (setv process2 (.Popen subprocess ["xargs" "git" "add"]
                         :stdin process1.stdout
                         :stdout subprocess.PIPE))
  (.close process1.stdout)
  (.communicate process2))

(defn exec-with-argument [command parser]
  (cond
    [parser.only-added (command "-o" "--exclude-standard")]
    [parser.only-modified (command "-m")]
    [parser.only-deleted (command "-d")]
    [parser.only-unmerged (command "-u")]))

(defn add [parser]
  (exec-with-argument git-add parser))

(defn show [parser]
  (print (exec-with-argument git-show parser)))

(defn add-arguments [parser]
  (.add-argument parser "--only-added" :action "store_true")
  (.add-argument parser "--only-unmerged" :action "store_true")
  (.add-argument parser "--only-deleted" :action "store_true")
  (.add-argument parser "--only-modified" :action "store_true"))

(defn init-parser []
  (setv parser (ArgumentParser :prog "PROG"))
  (let [subparsers (.add-subparsers parser :dest "command")
        add (.add-parser subparsers "add")
        show (.add-parser subparsers "show")]
       (add-arguments add)
       (add-arguments show))
  parser)

(defmain [&rest _]
  (setv parser (.parse-args (init-parser)))
  (cond
    [(= parser.command "add")
     (add parser)]
    [(= parser.command "show")
     (show parser)]))
