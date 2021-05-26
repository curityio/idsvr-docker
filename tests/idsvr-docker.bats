#!/usr/bin/env bats

load 'bats-support/load'
load 'bats-assert/load'

@test "Check that idsvr user can access idsvr content inside container" {
    run docker run -i $BATS_CURITY_IMAGE bash <<EOF
ls -l
EOF
    assert_success
    assert_line --index 1 -p 'bin'
    assert_line --index 2 -p 'etc'
    assert_line --index 3 -p 'lib'
    assert_line --index 4 -p 'usr'
    assert_line --index 5 -p 'var'
}

@test "Check that idsvr user cannot write on any file inside container" {
    run docker run -i $BATS_CURITY_IMAGE bash <<EOF
echo "TEST COMMENT" >> var/db/db.log
EOF
    assert_failure
    assert_output --partial 'Permission denied'
}

@test "Check that non-root/non-idsvr user cannot access any content inside container" {
    run docker run -i --user nobody $BATS_CURITY_IMAGE bash <<EOF
ls -l
EOF
    assert_failure
    assert_output --partial 'Permission denied'
}

@test "Check that idsvr user create log file inside container" {
    run docker run -i $BATS_CURITY_IMAGE bash <<EOF
echo "Test log writing" >> var/log/test.log
EOF
    assert_success "var/log/test.log"
}