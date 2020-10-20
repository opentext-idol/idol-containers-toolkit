
    create table annotation (
       imageFrame int4 not null,
        imageHeight int4 not null,
        imageTime timestamp not null,
        imageWidth int4 not null,
        label varchar(255),
        id varchar(255) not null,
        notesId int8,
        primary key (id)
    );

    create table annotationNotes (
       id  bigserial not null,
        text text not null,
        primary key (id)
    );

    create table face (
       confidence int4,
        database varchar(255),
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        name varchar(255),
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table keyframe (
       id varchar(255) not null,
        stream varchar(50) not null,
        time timestamp not null,
        imageHeight int4,
        image bytea,
        imagePath varchar(255),
        mimeType varchar(255),
        imageWidth int4,
        primary key (id)
    );

    create table licensePlate (
       confidence int4,
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        origin varchar(255),
        rawRead varchar(255),
        shape varchar(255),
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        vehicleColor1 int4,
        vehicleColor2 int4,
        vehicleColor3 int4,
        vehicleColorSpace varchar(255),
        vehicleColorName varchar(255),
        vehicleColorProportion int4,
        vehicleMake varchar(255),
        vehicleMakeConfidence int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table licensePlateRead (
       id  serial not null,
        text varchar(255) not null,
        licensePlate varchar(255),
        primary key (id)
    );

    create table logo (
       confidence int4,
        database varchar(255),
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        name varchar(255) not null,
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table ocr (
       confidence int4,
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        text varchar(255) not null,
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table program (
       category varchar(255),
        channel varchar(255),
        description varchar(255),
        quality varchar(255),
        title varchar(255) not null,
        id varchar(255) not null,
        primary key (id)
    );

    create table sceneAnalysis (
       category varchar(255),
        confidence int4,
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table searchableVideoEvent (
       id varchar(255) not null,
        searchableText varchar(255),
        primary key (id)
    );

    create table speaker (
       confidence int4,
        gender varchar(255),
        name varchar(255),
        id varchar(255) not null,
        primary key (id)
    );

    create table story (
       imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table storyTerm (
       id  serial not null,
        text varchar(255) not null,
        weight int4 not null,
        story varchar(255),
        primary key (id)
    );

    create table surveillance (
       alerttype varchar(255),
        category varchar(255),
        confidence int4,
        detector varchar(255),
        imageHeight int4,
        imageMimeType varchar(255),
        imagePath varchar(255),
        imageWidth int4,
        thumbnailHeight int4,
        thumbnailMimeType varchar(255),
        thumbnailPath varchar(255),
        thumbnailWidth int4,
        id varchar(255) not null,
        primary key (id)
    );

    create table videoEvent (
       id varchar(255) not null,
        endTime timestamp not null,
        startTime timestamp not null,
        stream varchar(50) not null,
        type varchar(255) not null,
        primary key (id)
    );

    create table word (
       id varchar(255) not null,
        stream varchar(50) not null,
        endTime timestamp not null,
        startTime timestamp not null,
        confidence int4,
        text varchar(255) not null,
        primary key (id)
    );

    alter table keyframe 
       add constraint keyframe_time_unq unique (stream, time);
create index event_stream_startTime_id_endTime_type_idx on videoEvent (stream, startTime, id, endTime, type);
create index word_stream_startTime_id_endTime_idx on word (stream, startTime, id, endTime);
create index word_stream_startTime_endTime_idx on word (stream, startTime, endTime);

    alter table annotation 
       add constraint FKjyieyp90ei64bk9u331ou9hd1 
       foreign key (notesId) 
       references annotationNotes 
       on delete cascade;

    alter table annotation 
       add constraint FKks1blew2yqrw0vcbbrlvnpl11 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table face 
       add constraint FK1ve9ltfqfufn7fqf10sqymo8y 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table licensePlate 
       add constraint FKf1ulnrocsacl2843gdvy4wrnb 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table licensePlateRead 
       add constraint FKib0sp3h07iy04rko1f05ybccx 
       foreign key (licensePlate) 
       references licensePlate 
       on delete cascade;

    alter table logo 
       add constraint FKmu6t6p67lj4mhfu8xarti1v01 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table ocr 
       add constraint FK7ww0rowql7s8vwnydx70489t9 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table program 
       add constraint FKb4ja1aqr7pm49l1dwj5wyl0nh 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table sceneAnalysis 
       add constraint FKesbcn045ptbdq82ifqb6bba59 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table speaker 
       add constraint FKk97thxt0c5rfsqh1j85rt3x4j 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table story 
       add constraint FK7wq88em3p7pok1j5jvpsfltd 
       foreign key (id) 
       references videoEvent 
       on delete cascade;

    alter table storyTerm 
       add constraint FKkgeiev5loidqx29npx4v8rvn9 
       foreign key (story) 
       references story 
       on delete cascade;

    alter table surveillance 
       add constraint FKmhkr30m69dcdv8rnrrgkq1b5a 
       foreign key (id) 
       references videoEvent 
       on delete cascade;