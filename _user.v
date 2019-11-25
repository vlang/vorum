//
module main

struct User {
mut:
	name string
}

fn (app App) retrieve_user(user_id int, random_id string) ?User {
	my := app.db
	users := my.exec_param('
		select name from users 
		where id=$user_id and random_id=$1', random_id)
	if users.len == 0 {
		return error('no such user "$user_id" r="$random_id"')
	}
	return User {
		name: users[0].vals[0] 
	}
}
