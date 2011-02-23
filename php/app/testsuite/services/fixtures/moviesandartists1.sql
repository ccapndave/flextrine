INSERT INTO `movie` (`id`,`title`) VALUES 
 (1,'Movie 1'),
 (2,'Movie 2');

INSERT INTO `artist` (`id`,`name`) VALUES 
 (1,'Artist 1'),
 (2,'Artist 2'),
 (3,'Artist 3');

INSERT INTO `movie_artist` (`Movie_id`,`Artist_id`) VALUES 
 (1,1),
 (1,2),
 (2,1),
 (2,2);