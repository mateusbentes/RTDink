//for start button

void main( void )
{
sp_x(1, 334);
   sp_y(1, 161);
   sp_base_walk(1, 70);
   sp_base_attack(1, 100);
    set_mode(2); //turn game on
reset_timer();
    sp_dir(1, 4);
    sp_brain(1, 1);
    sp_que(1, 0);
    sp_noclip(1, 0);
    //lets give him fists to start out with
    add_item("item-fst",438, 1);
    &cur_weapon = 1;
     //arm them for him too
//  initfont("SWEDISH");
    arm_weapon();
      //need this too
kill_this_task();

}
