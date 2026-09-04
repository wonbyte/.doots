;; extends

;; Upstream nvim-treesitter marks (line_comment) @indent.ignore, whose rule
;; is "a line positioned inside this node gets indent 0". The Rust parser's
;; line_comment node extends onto the following row, so the empty line you
;; create by pressing Enter after a comment counts as "inside" it and gets
;; indent 0 (nvim-treesitter issue #1336). Adding @indent.auto to the same
;; node wins because indent.lua checks indent.auto before indent.ignore:
;; it returns -1, which hands control to Neovim's 'autoindent', which copies
;; the comment line's indent. Regular comment lines themselves are
;; unaffected: the range check only triggers for the line AFTER the node.
(line_comment) @indent.auto
