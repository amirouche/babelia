(define-module (babelia app))

(import (scheme base))


(define-record-type <app>
  (make-app secret engine okvs ustore rstore nstore fts)
  app?
  (secret app-secret)
  (engine app-engine)
  (okvs app-okvs)
  (ustore app-ustore)
  (rstore app-rstore)
  (nstore app-nstore)
  (fts app-fts))

(export make-app)
(export app?)
(export app-secret)
(export app-engine)
(export app-okvs)
(export app-ustore)
(export app-rstore)
(export app-nstore)
(export app-fts)

(define-record-type <document>
  (make-document url title preview)
  document?
  (url document-url)
  (title document-title)
  (preview document-preview))

(export <document>)
(export make-document)
(export document?)
(export document-url)
(export document-title)
(export document-preview)
