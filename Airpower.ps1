$AirpowerPackages = 'go', 'node'

function AirpowerBuild {
	Airpower exec go, node, perl {
		gmake build
	}
}

function AirpowerClean {
	Airpower exec perl {
		gmake clean
	}
}

function AirpowerGo {
	param (
		[string]$Cmd,
		[string[]]$Apps
	)
	switch ($Cmd) {
		'build' {
			Airpower exec go, perl {
				gmake -f "$PSScriptRoot/Makefile" go-build "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'clean' {
			Airpower exec perl {
				gmake -f "$PSScriptRoot/Makefile" "$(if (-not $Apps -or 'tools' -in $Apps) { 'go-tools-clean' })" "$(if ('tools' -notin $Apps) { 'go-clean' })" "$(if ($Apps -and 'tools' -notin $Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'lint' {
			Airpower exec go, perl {
				gmake -f "$PSScriptRoot/Makefile" go-lint "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'test' {
			Airpower exec go, perl {
				gmake -f "$PSScriptRoot/Makefile" go-test "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		'update' {
			Airpower exec go, perl {
				gmake -f "$PSScriptRoot/Makefile" "$(if (-not $Apps -or 'tools' -in $Apps) { 'go-tools-update' })" "$(if ('tools' -notin $Apps) { 'go-update' })" "$(if ($Apps) { "GO_WORKS=$($Apps -join ' ')" })"
			}
		}
		default {
			Write-Error "bad command '$Cmd'"
		}
	}
}

function AirpowerLint {
	Airpower exec go, node, perl {
		gmake -f "$PSScriptRoot/Makefile" lint
	}
}

function AirpowerNode {
	param (
		[string]$Cmd,
		[string[]]$Apps
	)
	switch ($Cmd) {
		'build' {
			Airpower exec node, perl {
				gmake -f "$PSScriptRoot/Makefile" node-build "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'clean' {
			Airpower exec perl {
				gmake -f "$PSScriptRoot/Makefile" "$(if (-not $Apps -or 'cache' -in $Apps) { 'node-cache-clean' })" "$(if ('cache' -notin $Apps) { 'node-clean' })" "$(if ($Apps -and 'cache' -notin $Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'lint' {
			Airpower exec node, perl {
				gmake -f "$PSScriptRoot/Makefile" node-lint "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'test' {
			Airpower exec node, perl {
				gmake -f "$PSScriptRoot/Makefile" node-test "$(if ($Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		'update' {
			Airpower exec node, perl {
				gmake -f "$PSScriptRoot/Makefile" "$(if (-not $Apps -or 'cache' -in $Apps) { 'node-cache-update' })" "$(if ('cache' -notin $Apps) { 'node-update' })" "$(if ($Apps -and 'cache' -notin $Apps) { "NODE_WORKS=$($Apps -join ' ')" })"
			}
		}
		default {
			Write-Error "bad command '$Cmd'"
		}
	}
}

function AirpowerTest {
	Airpower exec go, node, perl {
		gmake -f "$PSScriptRoot/Makefile" test
	}
}

function AirpowerUpdate {
	Airpower exec go, node, perl {
		gmake -f "$PSScriptRoot/Makefile" update
	}
}
