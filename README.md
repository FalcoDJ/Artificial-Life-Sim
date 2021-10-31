# Artificial Life Simulator

### Rules for Organisms:

1. [x] There are 2 types of organisms (Chasers and Runners)
2. [x] look for parent if I donot have a parent. ( if am I runner, I only follow runners )
3. [x] if I am the leader in a group of 4 of my type, I change types, and if I am a runner
   scatter my children after making a new one, or else destroy my children if I am a chaser
4. [x] If I am the leader, Instead of bouncing off of walls I always like to move back
	toward the center of the world once I have moved a certain distance away from it
4. [x] I try to stay a certain distance away from my parent
5. [x] If I am a runner, when I have been scatter I don't look for a parent for 1 second.
