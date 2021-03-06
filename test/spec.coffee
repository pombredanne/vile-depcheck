_ = require "lodash"
path = require "path"
Bluebird = require "bluebird"
mimus = require "mimus"
lib = mimus.require "./../lib", __dirname, ["depcheck"]
chai = require "./helpers/sinon_chai"
sinon = require "sinon"
expect = chai.expect
vile = mimus.get lib, "vile"
depcheck = mimus.stub()

depcheck_returns = (dep, dev, invalid) ->
  depcheck.callsArgWith 2,
    dependencies: dep
    devDependencies: dev
    invalidFiles: invalid

describe "checking deps", ->
  afterEach mimus.reset

  before ->
    mimus.set lib, "depcheck", depcheck

  describe "config", ->
    beforeEach -> depcheck_returns [], [], []

    it "supports withoutDev", () ->
      lib
        .punish config: ignore_dev_deps: true
        .then ->
          depcheck.should.have.been
            .calledWith(
              process.cwd(),
              { ignoreDirs: [], ignoreMatches: [], withoutDev: true })

    it "supports ignoreDirs", () ->
      dirs = ["foo"]

      lib
        .punish config: ignore_dirs: dirs
        .then ->
          depcheck.should.have.been
            .calledWith(
              process.cwd(),
              { ignoreDirs: dirs, ignoreMatches: [], withoutDev: false })

    it "supports ignoreMatches", () ->
      pkgs = ["bar"]

      lib
        .punish config: ignore_deps: pkgs
        .then ->
          depcheck.should.have.been
            .calledWith(
              process.cwd(),
              { ignoreDirs: [], ignoreMatches: pkgs, withoutDev: false })

  describe "when unused deps found", ->
    before -> depcheck_returns ["foo"], [], []

    it "generates an error", ->
      issues = [vile.issue({
        type: vile.MAIN,
        path: "package.json",
        title: "unused module",
        message: "foo",
        signature: "depcheck::foo"
      })]

      lib.punish().should.become issues

  describe "when unused dev deps found", ->
    beforeEach -> depcheck_returns [], ["bar"], []

    it "generates a warning", ->
      issues = [vile.issue({
        type: vile.MAIN,
        path: "package.json",
        title: "unused dev module",
        message: "bar",
        signature: "depcheck::bar"
      })]

      lib.punish().should.become issues

  describe "when invalid files found", ->
    beforeEach -> depcheck_returns [], [], {file: { stack: "foo" } }

    it "generates an error", ->
      issues = [vile.issue({
        type: vile.ERR,
        path: "file",
        title: "invalid file",
        message: "foo",
        signature: "depcheck::invalid::file"
      })]

      lib.punish().should.become issues

  describe "when nothing is found", ->
    beforeEach -> depcheck_returns [], [], []

    it "generates an empty array", ->
      lib.punish().should.become []
