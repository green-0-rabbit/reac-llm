/* eslint-disable import/no-cycle */
/* eslint-disable @typescript-eslint/no-inferrable-types */
import { Entity, Property } from '@mikro-orm/sqlite';
import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';
import { CustomBaseEntity } from '../../common';
import { TodoRepository } from '../todo.repository';

type CustomOptionalProps = 'isCompleted';

@Entity({ repository: () => TodoRepository })
export class Todo extends CustomBaseEntity<
  TodoRepository,
  CustomOptionalProps
> {
  @Property()
  @ApiProperty({ description: 'Todo title' })
  @MaxLength(100)
  @IsString()
  title: string;

  @Property()
  @ApiProperty({ description: 'Is todo completed', default: false })
  @IsBoolean()
  isCompleted: boolean = false;

  @Property({ nullable: true })
  @ApiProperty({ description: 'Attachment URL', required: false })
  @IsString()
  @IsOptional()
  attachmentUrl?: string;
}
