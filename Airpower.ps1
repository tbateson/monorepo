Function AirpowerBuild {
	Airpower exec go, node, perl {
		gmake build
	}
}

Function AirpowerClean {
	Airpower exec perl {
		gmake clean
	}
}

Function AirpowerGo {
	param (
		[string]$Cmd,
		[string[]]$Apps
	)
	switch ($Cmd) {
		'build' {
			Airpower exec go, perl {
				gmake go-build "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'clean' {
			Airpower exec perl {
				gmake "$(if (-not $Apps -or 'tools' -in $Apps) { 'go-tools-clean' })" "$(if ('tools' -notin $Apps) { 'go-clean' })" "$(if ($Apps -and 'tools' -notin $Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'lint' {
			Airpower exec go, perl {
				gmake go-lint "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'test' {
			Airpower exec go, perl {
				gmake go-test "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'update' {
			Airpower exec go, perl {
				gmake "$(if (-not $Apps -or 'tools' -in $Apps) { 'go-tools-update' })" "$(if ('tools' -notin $Apps) { 'go-update' })" "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
	}
}

Function AirpowerLint {
	Airpower exec go, node, perl {
		gmake lint
	}
}

Function AirpowerNode {
	param (
		[string]$Cmd,
		[string[]]$Apps
	)
	switch ($Cmd) {
		'build' {
			Airpower exec node, perl {
				gmake node-build "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'clean' {
			Airpower exec perl {
				gmake "$(if (-not $Apps -or 'cache' -in $Apps) { 'node-cache-clean' })" "$(if ('cache' -notin $Apps) { 'node-clean' })" "$(if ($Apps -and 'cache' -notin $Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'lint' {
			Airpower exec node, perl {
				gmake node-lint "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'test' {
			Airpower exec node, perl {
				gmake node-test "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'update' {
			Airpower exec node, perl {
				gmake "$(if (-not $Apps -or 'cache' -in $Apps) { 'node-cache-update' })" "$(if ('cache' -notin $Apps) { 'node-update' })" "$(if ($Apps -and 'cache' -notin $Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
	}
}

Function AirpowerTest {
	Airpower exec go, node, perl {
		gmake test
	}
}

Function AirpowerUpdate {
	Airpower exec go, node, perl {
		gmake update
	}
}
