//
module main

struct User {
mut:
	id int
	name string
	is_banned bool
	is_admin bool
}


fn (app App) retrieve_user(user_id int, random_id string) ?User {
	//println('ret $user_id $random_id')
	db := app.db
	user := db.select from User where id==user_id && random_id == random_id
				limit 1 or { return none }
	return user
	/*
	users := my.exec_param('
		select name from users
		where id=$user_id and random_id=$1', random_id)
	if users.len == 0 {
		return error('no such user "$user_id" r="$random_id"')
	}
	return User {
		name: users[0].vals[0]
		//is_banned: users[0].vals[1] == 't'
	}
	*/
}
