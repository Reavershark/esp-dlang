#!/usr/bin/env bash
convert -resize '320x480!' zeus.svg png:- | stream -map r -storage-type char png:- zeus.raw
